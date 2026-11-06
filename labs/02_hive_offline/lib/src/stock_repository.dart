import 'dart:async';

import 'package:hive/hive.dart';

class StockItem {
  const StockItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int quantity;
  final DateTime updatedAt;

  bool get isLow => quantity <= 2;

  StockItem copyWith({int? quantity, DateTime? updatedAt}) => StockItem(
    id: id,
    title: title,
    quantity: quantity ?? this.quantity,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'quantity': quantity,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory StockItem.fromMap(Map<dynamic, dynamic> map) => StockItem(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 0,
    updatedAt:
        DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.itemId,
    required this.delta,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final int delta;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'item_id': itemId,
    'delta': delta,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory PendingOperation.fromMap(Map<dynamic, dynamic> map) =>
      PendingOperation(
        id: map['id']?.toString() ?? '',
        itemId: map['item_id']?.toString() ?? '',
        delta: map['delta'] is num ? (map['delta'] as num).toInt() : 0,
        createdAt:
            DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class StockRepository {
  StockRepository({required Box<dynamic> stock, required Box<dynamic> outbox})
    : _stock = stock,
      _outbox = outbox;

  static const String stockBoxName = 'stock_v1';
  static const String outboxBoxName = 'outbox_v1';

  final Box<dynamic> _stock;
  final Box<dynamic> _outbox;

  static Future<StockRepository> open() async => StockRepository(
    stock: await Hive.openBox<dynamic>(stockBoxName),
    outbox: await Hive.openBox<dynamic>(outboxBoxName),
  );

  List<StockItem> items() {
    final result = _stock.values
        .whereType<Map<dynamic, dynamic>>()
        .map(StockItem.fromMap)
        .where((item) => item.id.isNotEmpty)
        .toList();
    result.sort((a, b) => a.title.compareTo(b.title));
    return result;
  }

  List<PendingOperation> pending() => _outbox.values
      .whereType<Map<dynamic, dynamic>>()
      .map(PendingOperation.fromMap)
      .toList();

  Stream<List<StockItem>> watchItems() async* {
    yield items();
    await for (final _ in _changes()) {
      yield items();
    }
  }

  Stream<int> watchPendingCount() async* {
    yield _outbox.length;
    await for (final _ in _changes()) {
      yield _outbox.length;
    }
  }

  Future<void> seed(List<StockItem> items) async {
    await _stock.putAll({for (final item in items) item.id: item.toMap()});
  }

  Future<void> adjust(String itemId, int delta, {required bool online}) async {
    final raw = _stock.get(itemId);
    if (raw is! Map<dynamic, dynamic>) {
      return;
    }
    final current = StockItem.fromMap(raw);
    final next = current.copyWith(
      quantity: current.quantity + delta,
      updatedAt: DateTime.now(),
    );
    await _stock.put(itemId, next.toMap());

    if (!online) {
      final operation = PendingOperation(
        id: '${DateTime.now().microsecondsSinceEpoch}-$itemId',
        itemId: itemId,
        delta: delta,
        createdAt: DateTime.now(),
      );
      await _outbox.put(operation.id, operation.toMap());
    }
  }

  Future<int> flush() async {
    final operations = pending();
    for (final operation in operations) {
      await _outbox.delete(operation.id);
    }
    return operations.length;
  }

  Future<void> clear() async {
    await _stock.clear();
    await _outbox.clear();
  }

  Stream<void> _changes() {
    late StreamController<void> controller;
    final subscriptions = <StreamSubscription<BoxEvent>>[];

    void forward(BoxEvent _) {
      if (!controller.isClosed) {
        controller.add(null);
      }
    }

    controller = StreamController<void>(
      onListen: () {
        subscriptions
          ..add(_stock.watch().listen(forward))
          ..add(_outbox.watch().listen(forward));
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }
}
