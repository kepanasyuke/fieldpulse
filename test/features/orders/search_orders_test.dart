import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/usecases/search_orders.dart';

void main() {
  Order buildOrder({
    required String id,
    required String number,
    required String title,
    required String address,
    String customer = 'Клиент',
    OrderStatus status = OrderStatus.assigned,
  }) => Order(
    id: id,
    number: number,
    title: title,
    customer: customer,
    address: address,
    status: status,
    priority: OrderPriority.normal,
    updatedAt: DateTime.utc(2026, 11, 6),
  );

  group('SearchOrders', () {
    final orders = [
      buildOrder(
        id: '1',
        number: 'FP-1001',
        title: 'Замена счётчика',
        address: 'Москва, Ленинский пр-т, 42',
        customer: 'ООО «Ромашка»',
      ),
      buildOrder(
        id: '2',
        number: 'FP-1002',
        title: 'Настройка кассы',
        address: 'Москва, Тверская, 7',
        customer: 'ИП Петров',
        status: OrderStatus.done,
      ),
      buildOrder(
        id: '3',
        number: 'FP-2003',
        title: 'Подключение интернета',
        address: 'Казань, Баумана, 12',
        customer: 'ООО «Ромашка»',
      ),
    ];

    test('пустой запрос возвращает весь список', () async {
      final result = await const SearchOrders()(orders: orders, query: '   ');
      expect(result, hasLength(3));
    });

    test('ищет по всем полям и по нескольким токенам', () async {
      final result = await const SearchOrders()(
        orders: orders,
        query: 'ромашка москва',
      );
      expect(result.map((order) => order.id), ['1']);
    });

    test('ищет по номеру наряда без учёта регистра', () async {
      final result = await const SearchOrders()(orders: orders, query: 'fp-2003');
      expect(result.single.id, '3');
    });

    test('учитывает статус в поисковом индексе', () async {
      final result = await const SearchOrders()(orders: orders, query: 'закрыт');
      expect(result.single.id, '2');
    });

    test('на большом списке уходит в isolate и результат совпадает', () async {
      final big = List<Order>.generate(
        500,
        (index) => buildOrder(
          id: '$index',
          number: 'FP-${3000 + index}',
          title: index.isEven ? 'Плановое ТО' : 'Аварийный выезд',
          address: 'Москва, ул. Тестовая, $index',
        ),
      );

      final result = await const SearchOrders()(
        orders: big,
        query: 'аварийный',
      );

      expect(result, hasLength(250));
      expect(result.every((order) => order.title.contains('Аварийный')), isTrue);
    });
  });
}
