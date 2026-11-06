import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/utils/result.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';
import 'package:fieldpulse/features/orders/domain/usecases/search_orders.dart';
import 'package:fieldpulse/features/orders/presentation/bloc/orders_bloc.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

Order buildOrder({
  String id = 'o-1',
  String number = 'FP-1042',
  OrderStatus status = OrderStatus.assigned,
}) => Order(
  id: id,
  number: number,
  title: 'Замена счётчика',
  customer: 'ООО «Ромашка»',
  address: 'Москва, Ленинский пр-т, 42',
  status: status,
  priority: OrderPriority.high,
  updatedAt: DateTime.utc(2026, 11, 6, 9),
);

void main() {
  late _MockOrderRepository repository;
  late StreamController<List<Order>> cache;
  late StreamController<OrderEvent> events;
  late OrdersBloc bloc;

  setUp(() {
    repository = _MockOrderRepository();
    cache = StreamController<List<Order>>();
    events = StreamController<OrderEvent>();
    bloc = OrdersBloc(
      repository: repository,
      searchOrders: const SearchOrders(isolateThreshold: 1000),
    );

    when(() => repository.watchCachedOrders()).thenAnswer((_) => cache.stream);
    when(() => repository.watchEvents()).thenAnswer((_) => events.stream);
    when(
      () => repository.watchPendingUpdatesCount(),
    ).thenAnswer((_) => Stream<int>.value(2));
  });

  tearDown(() async {
    await cache.close();
    await events.close();
    await bloc.close();
  });

  test('стартует с загрузки и показывает кэш после синхронизации', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => Ok<List<Order>>([buildOrder()]));

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.status, OrdersListStatus.ready);
    expect(bloc.state.visibleOrders, hasLength(1));
    expect(bloc.state.pendingUpdates, 2);
    verify(
      () => repository.fetchOrders(forceRefresh: true),
    ).called(1);
  });

  test('остаётся рабочим на кэше, если сеть упала', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Err<List<Order>>(NetworkFailure()));

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    cache.add([buildOrder()]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.status, OrdersListStatus.ready);
    expect(bloc.state.visibleOrders, hasLength(1));
    expect(bloc.state.failure, null);
  });

  test('показывает ошибку, если нет ни сети, ни кэша', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Err<List<Order>>(NetworkFailure()));

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.status, OrdersListStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
  });

  test('поиск фильтрует и очищает список', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => Ok<List<Order>>([
        buildOrder(),
        buildOrder(id: 'o-2', number: 'FP-2000', status: OrderStatus.done),
      ]),
    );

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.visibleOrders, hasLength(2));

    bloc.add(const OrdersSearchChanged('FP-2000'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.visibleOrders.single.id, 'o-2');

    bloc.add(const OrdersSearchChanged(''));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.visibleOrders, hasLength(2));
  });

  test('фильтр по статусу комбинируется с поиском', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => Ok<List<Order>>([
        buildOrder(),
        buildOrder(id: 'o-2', number: 'FP-2000', status: OrderStatus.done),
      ]),
    );

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const OrdersFilterChanged(OrderStatus.done));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.visibleOrders.single.status, OrderStatus.done);

    bloc.add(const OrdersFilterChanged(null));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.visibleOrders, hasLength(2));
  });

  test('realtime-событие превращается в баннер', () async {
    when(
      () => repository.fetchOrders(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => Ok<List<Order>>([buildOrder()]));

    bloc.add(const OrdersStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    events.add(OrderUpsertedEvent(buildOrder(status: OrderStatus.done)));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.banner, contains('FP-1042'));
    expect(bloc.state.banner, contains('Закрыт'));
  });
}
