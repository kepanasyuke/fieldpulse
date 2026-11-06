import { logger } from "firebase-functions";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  GeoPoint,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 20, memory: "256MiB" });

const db = getFirestore();
const messaging = getMessaging();

const STATUSES = ["created", "assigned", "in_progress", "done", "cancelled"] as const;
type OrderStatus = (typeof STATUSES)[number];

const ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  created: ["assigned", "cancelled"],
  assigned: ["in_progress", "cancelled"],
  in_progress: ["done", "cancelled"],
  done: [],
  cancelled: [],
};

interface UpdateStatusPayload {
  orderId: string;
  status: OrderStatus;
  checkIn?: { lat: number; lng: number };
  comment?: string;
}

function assertTransition(from: OrderStatus, to: OrderStatus): void {
  if (!ALLOWED_TRANSITIONS[from]?.includes(to)) {
    throw new HttpsError(
      "failed-precondition",
      `Переход ${from} -> ${to} запрещён`,
    );
  }
}

export const updateOrderStatus = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Требуется авторизация");
  }

  const payload = request.data as UpdateStatusPayload;
  if (!payload?.orderId || !STATUSES.includes(payload.status)) {
    throw new HttpsError("invalid-argument", "orderId и status обязательны");
  }

  const orderRef = db.collection("orders").doc(payload.orderId);

  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(orderRef);
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Наряд не найден");
    }

    const order = snapshot.data() ?? {};
    if (order.assigneeId && order.assigneeId !== uid) {
      throw new HttpsError("permission-denied", "Наряд назначен другому инженеру");
    }

    const current = (order.status ?? "created") as OrderStatus;
    if (current === payload.status) {
      return { changed: false, current };
    }
    assertTransition(current, payload.status);

    if (payload.status === "done" && !order.photos?.length) {
      throw new HttpsError(
        "failed-precondition",
        "Закрытие наряда требует хотя бы одного фото",
      );
    }

    transaction.update(orderRef, {
      status: payload.status,
      updated_at: FieldValue.serverTimestamp(),
      status_history: FieldValue.arrayUnion({
        from: current,
        to: payload.status,
        by: uid,
        at: Timestamp.now(),
        check_in: payload.checkIn ?? null,
        comment: payload.comment ?? null,
      }),
      ...(payload.checkIn
        ? { last_check_in: new GeoPoint(payload.checkIn.lat, payload.checkIn.lng) }
        : {}),
    });

    return { changed: true, current };
  });

  if (!result.changed) {
    return { status: payload.status, changed: false };
  }

  await messaging
    .send({
      topic: "dispatchers",
      data: { order_id: payload.orderId, status: payload.status, event: "status_changed" },
      notification: {
        title: "Статус наряда обновлён",
        body: `${payload.orderId}: ${result.current} -> ${payload.status}`,
      },
    })
    .catch((error) => logger.warn("Не удалось отправить push диспетчерам", error));

  return { status: payload.status, changed: true };
});

export const registerDeviceToken = onCall(async (request) => {
  const uid = request.auth?.uid;
  const token = request.data?.token as string | undefined;
  if (!uid || !token) {
    throw new HttpsError("invalid-argument", "uid и token обязательны");
  }

  await db
    .collection("devices")
    .doc(uid)
    .collection("tokens")
    .doc(token)
    .set(
      {
        token,
        platform: request.data?.platform ?? "unknown",
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  await messaging.subscribeToTopic([token], `engineer_${uid}`).catch((error) =>
    logger.warn("subscribeToTopic failed", error),
  );

  return { ok: true };
});

export const notifyAssignee = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) {
    return;
  }

  await db.collection("order_events").add({
    order_id: event.params.orderId,
    from: before.status ?? null,
    to: after.status ?? null,
    created_at: FieldValue.serverTimestamp(),
  });

  const assigneeId = after.assigneeId as string | undefined;
  if (!assigneeId) {
    return;
  }

  await messaging
    .send({
      topic: `engineer_${assigneeId}`,
      data: {
        order_id: event.params.orderId,
        status: String(after.status ?? ""),
        event: "order_updated",
      },
      notification: {
        title: "Наряд обновлён",
        body: `${after.number ?? event.params.orderId}: ${after.status}`,
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default", "content-available": 1 } } },
    })
    .catch((error) => logger.warn("Не удалось отправить push инженеру", error));
});

export const archiveClosedOrders = onSchedule(
  { schedule: "every day 03:00", timeZone: "Europe/Moscow" },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const stale = await db
      .collection("orders")
      .where("status", "in", ["done", "cancelled"])
      .where("updated_at", "<", cutoff)
      .limit(400)
      .get();

    if (stale.empty) {
      logger.info("Нечего архивировать");
      return;
    }

    const batch = db.batch();
    stale.docs.forEach((doc) => batch.update(doc.ref, { archived: true }));
    await batch.commit();
    logger.info(`Архивировано нарядов: ${stale.size}`);
  },
);
