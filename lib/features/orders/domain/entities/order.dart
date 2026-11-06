import 'package:equatable/equatable.dart';

import 'package:fieldpulse/core/models/coordinates.dart';

enum OrderStatus {
  created('created', 'Новый'),
  assigned('assigned', 'Назначен'),
  inProgress('in_progress', 'В работе'),
  done('done', 'Закрыт'),
  cancelled('cancelled', 'Отменён');

  const OrderStatus(this.wire, this.label);

  final String wire;
  final String label;

  static OrderStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => OrderStatus.created,
  );

  bool get isTerminal => this == done || this == cancelled;

  List<OrderStatus> get nextSteps => switch (this) {
    OrderStatus.created => const [OrderStatus.assigned, OrderStatus.cancelled],
    OrderStatus.assigned => const [
      OrderStatus.inProgress,
      OrderStatus.cancelled,
    ],
    OrderStatus.inProgress => const [OrderStatus.done, OrderStatus.cancelled],
    OrderStatus.done || OrderStatus.cancelled => const [],
  };

  String get actionLabel => switch (this) {
    OrderStatus.assigned => 'Принять наряд',
    OrderStatus.inProgress => 'Начать работы',
    OrderStatus.done => 'Закрыть наряд',
    OrderStatus.cancelled => 'Отменить',
    OrderStatus.created => 'Вернуть в новые',
  };
}

enum OrderPriority {
  low('low', 'Низкий'),
  normal('normal', 'Обычный'),
  high('high', 'Высокий'),
  critical('critical', 'Критичный');

  const OrderPriority(this.wire, this.label);

  final String wire;
  final String label;

  static OrderPriority fromWire(String? value) => values.firstWhere(
    (priority) => priority.wire == value,
    orElse: () => OrderPriority.normal,
  );

  bool get isUrgent => this == high || this == critical;
}

class OrderPhoto extends Equatable {
  const OrderPhoto({
    required this.id,
    required this.url,
    required this.capturedAt,
    this.localPath,
  });

  final String id;
  final String url;
  final DateTime capturedAt;
  final String? localPath;

  bool get isUploaded => url.isNotEmpty;

  @override
  List<Object?> get props => [id, url, capturedAt, localPath];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.number,
    required this.title,
    required this.customer,
    required this.address,
    required this.status,
    required this.priority,
    required this.updatedAt,
    this.coordinates,
    this.comment,
    this.slaDueAt,
    this.photos = const [],
    this.hasPendingUpdate = false,
  });

  final String id;
  final String number;
  final String title;
  final String customer;
  final String address;
  final OrderStatus status;
  final OrderPriority priority;
  final DateTime updatedAt;
  final Coordinates? coordinates;
  final String? comment;
  final DateTime? slaDueAt;
  final List<OrderPhoto> photos;
  final bool hasPendingUpdate;

  bool get isOverdue =>
      !status.isTerminal &&
      slaDueAt != null &&
      slaDueAt!.isBefore(DateTime.now());

  String get subtitle => '$number · $customer';

  Order copyWith({
    String? number,
    String? title,
    String? customer,
    String? address,
    OrderStatus? status,
    OrderPriority? priority,
    DateTime? updatedAt,
    Coordinates? coordinates,
    String? comment,
    DateTime? slaDueAt,
    List<OrderPhoto>? photos,
    bool? hasPendingUpdate,
  }) => Order(
    id: id,
    number: number ?? this.number,
    title: title ?? this.title,
    customer: customer ?? this.customer,
    address: address ?? this.address,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    updatedAt: updatedAt ?? this.updatedAt,
    coordinates: coordinates ?? this.coordinates,
    comment: comment ?? this.comment,
    slaDueAt: slaDueAt ?? this.slaDueAt,
    photos: photos ?? this.photos,
    hasPendingUpdate: hasPendingUpdate ?? this.hasPendingUpdate,
  );

  @override
  List<Object?> get props => [
    id,
    number,
    title,
    customer,
    address,
    status,
    priority,
    updatedAt,
    coordinates,
    comment,
    slaDueAt,
    photos,
    hasPendingUpdate,
  ];
}
