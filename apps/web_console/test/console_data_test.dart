import 'package:flutter_test/flutter_test.dart';

import 'package:web_console/src/console_data.dart';

void main() {
  group('ConsoleMetrics', () {
    test('считает всего, в работе и просроченные', () {
      final metrics = ConsoleMetrics.of(demoOrders());

      expect(metrics.total, 5);
      expect(metrics.inProgress, 2);
      expect(metrics.overdue, 2);
    });

    test('пустой список даёт нули', () {
      final metrics = ConsoleMetrics.of(const []);

      expect(metrics.total, 0);
      expect(metrics.overdue, 0);
    });
  });

  group('ConsoleOrder', () {
    test('закрытый наряд не считается просроченным по подписи', () {
      const order = ConsoleOrder(
        number: 'FP-1',
        client: 'Клиент',
        status: 'закрыт',
        slaMinutes: -300,
      );

      expect(order.isClosed, isTrue);
      expect(order.slaLabel, '—');
    });

    test('просроченный наряд показывает дельту', () {
      const order = ConsoleOrder(
        number: 'FP-2',
        client: 'Клиент',
        status: 'в работе',
        slaMinutes: -20,
      );

      expect(order.isOverdue, isTrue);
      expect(order.slaLabel, 'просрочен на 20 мин');
    });
  });

  group('сортировка и фильтры', () {
    test('сортировка по SLA ставит самые срочные первыми', () {
      final sorted = sortBySla(demoOrders());

      expect(sorted.first.number, 'FP-1046');
      expect(sorted.last.slaMinutes, 120);
    });

    test('фильтр по статусу возвращает только нужные наряды', () {
      final filtered = filterByStatus(demoOrders(), 'в работе');

      expect(filtered, hasLength(2));
      expect(filtered.every((order) => order.status == 'в работе'), isTrue);
    });

    test('пустой фильтр возвращает всё', () {
      expect(filterByStatus(demoOrders(), null), hasLength(5));
    });

    test('варианты статусов уникальны и начинаются с «Все»', () {
      final options = statusOptions(demoOrders());

      expect(options.first, 'Все');
      expect(options.toSet().length, options.length);
    });
  });
}
