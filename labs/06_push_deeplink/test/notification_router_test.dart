import 'package:flutter_test/flutter_test.dart';

import 'package:lab_push_deeplink/src/notification_router.dart';

void main() {
  group('PushPayload', () {
    test('разбирает payload наряда', () {
      final payload = PushPayload.fromData({
        'message_id': 'm-1',
        'type': 'order_updated',
        'order_id': 'o-1',
        'title': 'Наряд обновлён',
      });

      expect(payload.type, PushType.orderUpdated);
      expect(payload.orderId, 'o-1');
    });

    test('неизвестный тип считается broadcast', () {
      final payload = PushPayload.fromData({'message_id': 'm-2', 'type': 'x'});

      expect(payload.type, PushType.broadcast);
    });
  });

  group('NotificationRouter', () {
    test('ведёт на карточку наряда', () {
      final router = NotificationRouter();
      final link = router.resolve(
        const PushPayload(
          messageId: 'm-1',
          type: PushType.orderUpdated,
          orderId: 'o-42',
        ),
      );

      expect(link, isA<OrderDeepLink>());
      expect(link.toString(), '/orders/o-42');
    });

    test('ведёт в чат по наряду', () {
      final router = NotificationRouter();
      final link = router.resolve(
        const PushPayload(
          messageId: 'm-2',
          type: PushType.chatMessage,
          orderId: 'o-7',
        ),
      );

      expect(link.toString(), '/orders/o-7/chat');
    });

    test('broadcast открывает ленту', () {
      final router = NotificationRouter();
      final link = router.resolve(
        const PushPayload(messageId: 'm-3', type: PushType.broadcast),
      );

      expect(link.toString(), '/feed');
    });

    test('без order_id ссылка не строится', () {
      final router = NotificationRouter();
      final link = router.resolve(
        const PushPayload(messageId: 'm-4', type: PushType.orderUpdated),
      );

      expect(link, isNull);
    });

    test('повторный push с тем же message_id игнорируется', () {
      final router = NotificationRouter();
      const payload = PushPayload(
        messageId: 'm-5',
        type: PushType.orderUpdated,
        orderId: 'o-9',
      );

      expect(router.resolve(payload), isNotNull);
      expect(router.resolve(payload), isNull);
      expect(router.handledIds, ['m-5']);
    });

    test('push без message_id не обрабатывается', () {
      final router = NotificationRouter();
      final link = router.resolve(
        const PushPayload(messageId: '', type: PushType.broadcast),
      );

      expect(link, isNull);
    });
  });
}
