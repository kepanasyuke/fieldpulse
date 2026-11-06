import 'package:equatable/equatable.dart';

import 'package:fieldpulse/features/orders/domain/entities/order.dart';

class OrderComment extends Equatable {
  const OrderComment({
    required this.orderId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String orderId;
  final String author;
  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [orderId, author, text, createdAt];
}

sealed class OrderEvent {
  const OrderEvent();
}

final class OrdersSnapshotEvent extends OrderEvent {
  const OrdersSnapshotEvent(this.orders);

  final List<Order> orders;
}

final class OrderUpsertedEvent extends OrderEvent {
  const OrderUpsertedEvent(this.order, {this.reason});

  final Order order;
  final String? reason;
}

final class OrderRemovedEvent extends OrderEvent {
  const OrderRemovedEvent(this.orderId);

  final String orderId;
}

final class OrderCommentEvent extends OrderEvent {
  const OrderCommentEvent(this.comment);

  final OrderComment comment;
}

final class OrderConnectionEvent extends OrderEvent {
  const OrderConnectionEvent({required this.online});

  final bool online;
}
