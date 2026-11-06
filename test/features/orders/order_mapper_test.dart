import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';

void main() {
  const mapper = OrderMapper();

  group('OrderMapper', () {
    test('маппит DTO в доменную модель', () {
      final dto = OrderDto(
        id: 'o-1',
        number: 'FP-1042',
        title: 'Замена счётчика',
        customer: 'ООО «Ромашка»',
        address: 'Москва, Ленинский пр-т, 42',
        status: 'in_progress',
        priority: 'critical',
        updatedAt: DateTime.utc(2026, 11, 6, 9, 30),
        slaDueAt: DateTime.utc(2026, 11, 6, 12),
        photos: [
          OrderPhotoDto(
            id: 'p-1',
            url: 'https://cdn.fieldpulse.dev/p-1.jpg',
            capturedAt: DateTime.utc(2026, 11, 6, 9, 15),
          ),
        ],
      );

      final order = mapper.toDomain(dto);

      expect(order.status, OrderStatus.inProgress);
      expect(order.priority, OrderPriority.critical);
      expect(order.photos, hasLength(1));
      expect(order.photos.first.isUploaded, isTrue);
    });

    test('неизвестный статус не ломает парсинг', () {
      final dto = OrderDto.fromJson({
        'id': 'o-2',
        'status': 'pending_dispatch',
        'priority': 'whatever',
        'updated_at': '2026-11-06T09:30:00Z',
      });

      final order = mapper.toDomain(dto);

      expect(order.status, OrderStatus.created);
      expect(order.priority, OrderPriority.normal);
    });

    test('сохраняет координаты из location и переживает round-trip', () {
      final dto = OrderDto.fromJson({
        'id': 'o-3',
        'number': 'FP-2000',
        'title': 'Диагностика',
        'customer': 'Кофейня',
        'address': 'Тверская, 7',
        'status': 'assigned',
        'priority': 'high',
        'updated_at': '2026-11-06T09:30:00Z',
        'location': {'lat': 55.7601, 'lng': 37.6110, 'accuracy': 8.5},
        'photos': <dynamic>[],
      });

      expect(dto.coordinates?.latitude, 55.7601);

      final restored = OrderDto.fromJson(dto.toJson());
      expect(restored.coordinates?.longitude, 37.6110);
      expect(restored.coordinates?.accuracyMeters, 8.5);
      expect(restored.status, 'assigned');
    });

    test('устойчив к «мусорным» полям и пустому фото-массиву', () {
      final dto = OrderDto.fromJson({
        'id': 'o-4',
        'location': {'lat': 'not a number', 'lng': null},
        'photos': [1, 2, 3],
      });

      expect(dto.coordinates, isNull);
      expect(dto.photos, isEmpty);
    });
  });
}
