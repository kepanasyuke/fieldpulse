import 'dart:isolate';

import 'package:fieldpulse/features/orders/domain/entities/order.dart';

class SearchOrders {
  const SearchOrders({this.isolateThreshold = 120});

  final int isolateThreshold;

  Future<List<Order>> call({
    required List<Order> orders,
    required String query,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return Future.value(orders);
    }
    if (orders.length < isolateThreshold) {
      return Future.value(_filter(orders, normalized));
    }
    return Isolate.run(() => _filter(orders, normalized));
  }

  List<Order> _filter(List<Order> orders, String query) {
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return orders.where((order) {
      final haystack = [
        order.number,
        order.title,
        order.customer,
        order.address,
        order.status.label,
        order.comment ?? '',
      ].join(' ').toLowerCase();
      return tokens.every(haystack.contains);
    }).toList(growable: false);
  }
}
