import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
import 'package:fieldpulse/features/orders/data/outbox/pending_action.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';

class OrderLocalDataSource {
  OrderLocalDataSource({
    required Box<dynamic> ordersBox,
    required Box<dynamic> outboxBox,
    required OrderMapper mapper,
  }) : _ordersBox = ordersBox,
       _outboxBox = outboxBox,
       _mapper = mapper;

  final Box<dynamic> _ordersBox;
  final Box<dynamic> _outboxBox;
  final OrderMapper _mapper;

  List<PendingAction> readPendingActions() =>
      _outboxBox.values
          .whereType<Map<dynamic, dynamic>>()
          .map(PendingAction.fromMap)
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Set<String> get _pendingOrderIds =>
      readPendingActions().map((action) => action.orderId).toSet();

  Order? _orderFrom(Object? value, Set<String> pending) {
    if (value is! Map<dynamic, dynamic>) {
      return null;
    }
    final dto = OrderDto.fromJson(Map<String, dynamic>.from(value));
    if (dto.id.isEmpty) {
      return null;
    }
    final order = _mapper.toDomain(dto);

    return order.copyWith(hasPendingUpdate: pending.contains(order.id));
  }

  List<Order> readOrders() {
    final orders = _ordersFrom(_pendingOrderIds)..sort(_byPriorityThenDate);

    return orders;
  }

  List<Order> _ordersFrom(Set<String> pending) {
    final orders = <Order>[];
    for (final value in _ordersBox.values) {
      final order = _orderFrom(value, pending);
      if (order != null) {
        orders.add(order);
      }
    }

    return orders;
  }

  int _byPriorityThenDate(Order first, Order second) {
    if (first.priority.index != second.priority.index) {
      return second.priority.index.compareTo(first.priority.index);
    }

    return first.updatedAt.compareTo(second.updatedAt);
  }

  Order? findById(String orderId) {
    final value = _ordersBox.get(orderId);
    if (value is! Map<dynamic, dynamic>) {
      return null;
    }
    final dto = OrderDto.fromJson(Map<String, dynamic>.from(value));
    final order = _mapper.toDomain(dto);
    return order.copyWith(
      hasPendingUpdate: _pendingOrderIds.contains(order.id),
    );
  }

  Future<void> saveOrders(List<Order> orders) async {
    final incoming = <String, dynamic>{
      for (final order in orders) order.id: _mapper.toDto(order).toJson(),
    };
    final staleIds = _ordersBox.keys
        .whereType<String>()
        .where((key) => !incoming.containsKey(key))
        .toList(growable: false);

    await _ordersBox.putAll(incoming);
    if (staleIds.isNotEmpty) {
      await _ordersBox.deleteAll(staleIds);
    }
  }

  Future<void> upsert(Order order) =>
      _ordersBox.put(order.id, _mapper.toDto(order).toJson());

  Future<void> remove(String orderId) => _ordersBox.delete(orderId);

  Future<void> enqueue(PendingAction action) =>
      _outboxBox.put(action.id, action.toMap());

  Future<void> dropPending(String actionId) => _outboxBox.delete(actionId);

  Future<void> clearPending() => _outboxBox.clear();

  Future<void> clear() async {
    await _ordersBox.clear();
    await _outboxBox.clear();
  }

  Stream<List<Order>> watchOrders() async* {
    yield readOrders();
    await for (final _ in _watchChanges()) {
      yield readOrders();
    }
  }

  Stream<int> watchPendingCount() async* {
    yield _outboxBox.length;
    await for (final _ in _watchChanges()) {
      yield _outboxBox.length;
    }
  }

  Stream<void> _watchChanges() {
    late StreamController<void> controller;
    final subscriptions = <StreamSubscription<BoxEvent>>[];

    controller = StreamController<void>(
      onListen: () => _listenChanges(controller, subscriptions),
      onCancel: () => _stopWatching(controller, subscriptions),
    );

    return controller.stream;
  }

  void _listenChanges(
    StreamController<void> controller,
    List<StreamSubscription<BoxEvent>> subscriptions,
  ) {
    subscriptions
      ..add(_ordersBox.watch().listen((_) => _notify(controller)))
      ..add(_outboxBox.watch().listen((_) => _notify(controller)));
  }

  void _notify(StreamController<void> controller) {
    if (!controller.isClosed) {
      controller.add(null);
    }
  }

  Future<void> _stopWatching(
    StreamController<void> controller,
    List<StreamSubscription<BoxEvent>> subscriptions,
  ) async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    subscriptions.clear();
    await controller.close();
  }

  static bool sameOrders(List<Order> a, List<Order> b) => listEquals(a, b);
}
