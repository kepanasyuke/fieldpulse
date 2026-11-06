import 'package:fieldpulse/core/models/coordinates.dart';
import 'package:fieldpulse/core/utils/result.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';

abstract interface class OrderRepository {
  Future<Result<List<Order>>> fetchOrders({bool forceRefresh = false});

  Future<Result<Order>> fetchOrder(String orderId);

  Stream<List<Order>> watchCachedOrders();

  Stream<OrderEvent> watchEvents();

  Future<Result<void>> changeStatus({
    required String orderId,
    required OrderStatus status,
    Coordinates? checkIn,
  });

  Future<Result<void>> attachPhoto({
    required String orderId,
    required String filePath,
  });

  Future<void> flushPendingUpdates();

  Stream<int> watchPendingUpdatesCount();
}
