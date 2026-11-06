import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpulse/features/orders/data/outbox/pending_action.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';

void main() {
  group('PendingAction', () {
    test('сериализуется и читается без потерь', () {
      final action = PendingAction(
        id: 'req-1',
        orderId: 'o-42',
        type: PendingActionType.status,
        createdAt: DateTime.utc(2026, 11, 6, 10, 15),
        status: OrderStatus.inProgress.wire,
        latitude: 55.7601,
        longitude: 37.611,
      );

      final restored = PendingAction.fromMap(action.toMap());

      expect(restored.id, 'req-1');
      expect(restored.orderStatus, OrderStatus.inProgress);
      expect(restored.latitude, 55.7601);
      expect(restored.attempts, 0);
    });

    test('неизвестный тип действия не роняет очередь', () {
      final restored = PendingAction.fromMap({
        'id': 'req-2',
        'order_id': 'o-43',
        'type': 'unknown',
        'created_at': '2026-11-06T10:15:00Z',
      });

      expect(restored.type, PendingActionType.status);
      expect(restored.orderStatus, isNull);
    });

    test('увеличивает счётчик попыток, не теряя данные', () {
      final action = PendingAction(
        id: 'req-3',
        orderId: 'o-44',
        type: PendingActionType.photo,
        createdAt: DateTime.utc(2026, 11, 6),
        filePath: '/tmp/photo.jpg',
      );

      final retried = action.nextAttempt();

      expect(retried.attempts, 1);
      expect(retried.filePath, action.filePath);
      expect(retried.type, PendingActionType.photo);
    });
  });
}
