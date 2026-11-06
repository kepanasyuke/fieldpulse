import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';
import 'package:fieldpulse/features/orders/domain/usecases/search_orders.dart';

sealed class OrdersEvent {
  const OrdersEvent();
}

final class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

final class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}

final class OrdersSearchChanged extends OrdersEvent {
  const OrdersSearchChanged(this.query);

  final String query;
}

final class OrdersFilterChanged extends OrdersEvent {
  const OrdersFilterChanged(this.status);

  final OrderStatus? status;
}

final class OrdersCacheSynced extends OrdersEvent {
  const OrdersCacheSynced(this.orders);

  final List<Order> orders;
}

final class OrdersRemoteEventReceived extends OrdersEvent {
  const OrdersRemoteEventReceived(this.event);

  final OrderEvent event;
}

final class OrdersPendingCountChanged extends OrdersEvent {
  const OrdersPendingCountChanged(this.count);

  final int count;
}

final class OrdersSyncRequested extends OrdersEvent {
  const OrdersSyncRequested();
}

enum OrdersListStatus { initial, loading, ready, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersListStatus.initial,
    this.allOrders = const [],
    this.visibleOrders = const [],
    this.query = '',
    this.statusFilter,
    this.failure,
    this.pendingUpdates = 0,
    this.isRefreshing = false,
    this.banner,
  });

  final OrdersListStatus status;
  final List<Order> allOrders;
  final List<Order> visibleOrders;
  final String query;
  final OrderStatus? statusFilter;
  final Failure? failure;
  final int pendingUpdates;
  final bool isRefreshing;
  final String? banner;

  bool get isEmpty => status == OrdersListStatus.ready && visibleOrders.isEmpty;

  bool get hasFilters => query.isNotEmpty || statusFilter != null;

  int get urgentCount => visibleOrders.where((order) => order.isOverdue).length;

  OrdersState copyWith({
    OrdersListStatus? status,
    List<Order>? allOrders,
    List<Order>? visibleOrders,
    String? query,
    OrderStatus? statusFilter,
    Failure? failure,
    int? pendingUpdates,
    bool? isRefreshing,
    String? banner,
    bool clearBanner = false,
    bool clearFailure = false,
    bool clearStatusFilter = false,
  }) => OrdersState(
    status: status ?? this.status,
    allOrders: allOrders ?? this.allOrders,
    visibleOrders: visibleOrders ?? this.visibleOrders,
    query: query ?? this.query,
    statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
    failure: clearFailure ? null : failure ?? this.failure,
    pendingUpdates: pendingUpdates ?? this.pendingUpdates,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    banner: clearBanner ? null : banner ?? this.banner,
  );

  @override
  List<Object?> get props => [
    status,
    allOrders,
    visibleOrders,
    query,
    statusFilter,
    failure,
    pendingUpdates,
    isRefreshing,
    banner,
  ];
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required OrderRepository repository,
    required SearchOrders searchOrders,
  }) : _repository = repository,
       _searchOrders = searchOrders,
       super(const OrdersState()) {
    on<OrdersStarted>(_onStarted);
    on<OrdersRefreshed>(_onRefreshed);
    on<OrdersSearchChanged>(_onSearchChanged);
    on<OrdersFilterChanged>(_onFilterChanged);
    on<OrdersCacheSynced>(_onCacheSynced);
    on<OrdersRemoteEventReceived>(_onRemoteEvent);
    on<OrdersPendingCountChanged>(_onPendingCountChanged);
    on<OrdersSyncRequested>(_onSyncRequested);
  }

  final OrderRepository _repository;
  final SearchOrders _searchOrders;

  final List<StreamSubscription<void>> _subscriptions = [];
  int _searchToken = 0;

  Future<void> _onStarted(
    OrdersStarted event,
    Emitter<OrdersState> emit,
  ) async {
    if (_subscriptions.isNotEmpty) {
      return;
    }
    emit(state.copyWith(status: OrdersListStatus.loading));

    _subscriptions.add(
      _repository.watchCachedOrders().listen(
        (orders) => add(OrdersCacheSynced(orders)),
      ),
    );
    _subscriptions.add(
      _repository.watchEvents().listen(
        (remoteEvent) => add(OrdersRemoteEventReceived(remoteEvent)),
      ),
    );
    _subscriptions.add(
      _repository.watchPendingUpdatesCount().listen(
        (count) => add(OrdersPendingCountChanged(count)),
      ),
    );

    add(const OrdersRefreshed());
  }

  Future<void> _onRefreshed(
    OrdersRefreshed event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearFailure: true));

    final result = await _repository.fetchOrders(forceRefresh: true);
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        state.copyWith(
          isRefreshing: false,
          status: state.allOrders.isEmpty
              ? OrdersListStatus.failure
              : OrdersListStatus.ready,
          failure: failure,
        ),
      );
      return;
    }

    final orders = result.valueOrNull ?? const <Order>[];
    final visible = await _searchOrders(
      orders: _applyFilter(orders),
      query: state.query,
    );
    emit(
      state.copyWith(
        status: OrdersListStatus.ready,
        allOrders: orders,
        visibleOrders: visible,
        isRefreshing: false,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onCacheSynced(
    OrdersCacheSynced event,
    Emitter<OrdersState> emit,
  ) async {
    final visible = await _searchOrders(
      orders: _applyFilter(event.orders),
      query: state.query,
    );
    emit(
      state.copyWith(
        status: OrdersListStatus.ready,
        allOrders: event.orders,
        visibleOrders: visible,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSearchChanged(
    OrdersSearchChanged event,
    Emitter<OrdersState> emit,
  ) async {
    final token = ++_searchToken;
    final visible = await _searchOrders(
      orders: _applyFilter(state.allOrders),
      query: event.query,
    );
    if (token != _searchToken) {
      return;
    }
    emit(state.copyWith(query: event.query, visibleOrders: visible));
  }

  Future<void> _onFilterChanged(
    OrdersFilterChanged event,
    Emitter<OrdersState> emit,
  ) async {
    final token = ++_searchToken;
    final orders = _applyFilter(
      state.allOrders,
      status: event.status,
      strict: true,
    );
    final visible = await _searchOrders(orders: orders, query: state.query);
    if (token != _searchToken) {
      return;
    }
    emit(
      state.copyWith(
        statusFilter: event.status,
        clearStatusFilter: event.status == null,
        visibleOrders: visible,
      ),
    );
  }

  void _onRemoteEvent(
    OrdersRemoteEventReceived event,
    Emitter<OrdersState> emit,
  ) {
    final message = switch (event.event) {
      OrderUpsertedEvent(:final order) =>
        'Наряд ${order.number}: ${order.status.label}',
      OrderRemovedEvent() => 'Наряд снят с назначения',
      OrderCommentEvent(:final comment) => '${comment.author}: ${comment.text}',
      OrderConnectionEvent(:final online) =>
        online ? 'Связь восстановлена' : 'Работаем офлайн',
      OrdersSnapshotEvent() => 'Список нарядов синхронизирован',
    };
    emit(state.copyWith(banner: message));
  }

  void _onPendingCountChanged(
    OrdersPendingCountChanged event,
    Emitter<OrdersState> emit,
  ) {
    emit(state.copyWith(pendingUpdates: event.count));
  }

  Future<void> _onSyncRequested(
    OrdersSyncRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearFailure: true));
    await _repository.flushPendingUpdates();
    final result = await _repository.fetchOrders(forceRefresh: true);
    emit(
      state.copyWith(
        isRefreshing: false,
        failure: result.failureOrNull,
        banner: result.failureOrNull == null ? 'Данные синхронизированы' : null,
      ),
    );
  }

  List<Order> _applyFilter(
    List<Order> orders, {
    OrderStatus? status,
    bool strict = false,
  }) {
    final filter = strict ? status : status ?? state.statusFilter;
    if (filter == null) {
      return orders;
    }
    return orders
        .where((order) => order.status == filter)
        .toList(growable: false);
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }
}
