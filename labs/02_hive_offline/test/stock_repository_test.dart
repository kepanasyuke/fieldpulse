import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lab_hive_offline/src/stock_repository.dart';

void main() {
  late StockRepository repository;

  setUpAll(() {
    final dir = Directory.systemTemp.createTempSync('lab02_hive');
    Hive.init(dir.path);
  });

  setUp(() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    repository = StockRepository(
      stock: await Hive.openBox<dynamic>('stock_test_$suffix'),
      outbox: await Hive.openBox<dynamic>('outbox_test_$suffix'),
    );
  });

  tearDown(() async {
    await repository.clear();
  });

  test('начальное состояние и сортировка по названию', () async {
    await repository.seed([
      StockItem(
        id: 'b',
        title: 'Пломба',
        quantity: 2,
        updatedAt: DateTime.utc(2026),
      ),
      StockItem(
        id: 'a',
        title: 'Кабель',
        quantity: 10,
        updatedAt: DateTime.utc(2026),
      ),
    ]);

    final items = repository.items();

    expect(items.map((item) => item.title), ['Кабель', 'Пломба']);
    expect(items.last.isLow, isTrue);
  });

  test('изменение в онлайне не создаёт очередь', () async {
    await repository.seed([
      StockItem(
        id: 'a',
        title: 'Кабель',
        quantity: 10,
        updatedAt: DateTime.utc(2026),
      ),
    ]);

    await repository.adjust('a', -3, online: true);

    expect(repository.items().single.quantity, 7);
    expect(repository.pending(), isEmpty);
  });

  test(
    'изменение в офлайне попадает в очередь и применяется локально',
    () async {
      await repository.seed([
        StockItem(
          id: 'a',
          title: 'Кабель',
          quantity: 10,
          updatedAt: DateTime.utc(2026),
        ),
      ]);

      await repository.adjust('a', -4, online: false);

      expect(repository.items().single.quantity, 6);
      expect(repository.pending().single.delta, -4);
    },
  );

  test('flush очищает очередь и возвращает число операций', () async {
    await repository.seed([
      StockItem(
        id: 'a',
        title: 'Кабель',
        quantity: 10,
        updatedAt: DateTime.utc(2026),
      ),
    ]);
    await repository.adjust('a', 1, online: false);
    await repository.adjust('a', 2, online: false);

    final sent = await repository.flush();

    expect(sent, 2);
    expect(repository.pending(), isEmpty);
  });

  test('правка неизвестной позиции игнорируется', () async {
    await repository.adjust('missing', 5, online: true);

    expect(repository.items(), isEmpty);
    expect(repository.pending(), isEmpty);
  });

  test('watchItems отдаёт обновления после правки', () async {
    await repository.seed([
      StockItem(
        id: 'a',
        title: 'Кабель',
        quantity: 1,
        updatedAt: DateTime.utc(2026),
      ),
    ]);

    final emissions = <int>[];
    final subscription = repository.watchItems().listen(
      (items) => emissions.add(items.isEmpty ? 0 : items.single.quantity),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.adjust('a', 5, online: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.first, 1);
    expect(emissions.last, 6);

    await subscription.cancel();
  });
}
