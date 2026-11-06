import 'package:fieldpulse/features/orders/domain/entities/order.dart';

enum PendingActionType { status, photo }

class PendingAction {
  const PendingAction({
    required this.id,
    required this.orderId,
    required this.type,
    required this.createdAt,
    this.status,
    this.filePath,
    this.latitude,
    this.longitude,
    this.attempts = 0,
  });

  final String id;
  final String orderId;
  final PendingActionType type;
  final DateTime createdAt;
  final String? status;
  final String? filePath;
  final double? latitude;
  final double? longitude;
  final int attempts;

  PendingAction nextAttempt() => PendingAction(
    id: id,
    orderId: orderId,
    type: type,
    createdAt: createdAt,
    status: status,
    filePath: filePath,
    latitude: latitude,
    longitude: longitude,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'type': type.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    if (status != null) 'status': status,
    if (filePath != null) 'file_path': filePath,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    'attempts': attempts,
  };

  factory PendingAction.fromMap(Map<dynamic, dynamic> map) => PendingAction(
    id: map['id'] as String? ?? '',
    orderId: map['order_id'] as String? ?? '',
    type: PendingActionType.values.firstWhere(
      (value) => value.name == map['type'],
      orElse: () => PendingActionType.status,
    ),
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    status: map['status'] as String?,
    filePath: map['file_path'] as String?,
    latitude: (map['lat'] as num?)?.toDouble(),
    longitude: (map['lng'] as num?)?.toDouble(),
    attempts: (map['attempts'] as num?)?.toInt() ?? 0,
  );

  OrderStatus? get orderStatus =>
      status == null ? null : OrderStatus.fromWire(status);
}
