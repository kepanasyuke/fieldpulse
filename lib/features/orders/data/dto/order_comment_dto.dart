import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';

class OrderCommentDto {
  const OrderCommentDto({
    required this.orderId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String orderId;
  final String author;
  final String text;
  final DateTime createdAt;

  factory OrderCommentDto.fromJson(Map<String, dynamic> json) => OrderCommentDto(
    orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
    author: json['author'] as String? ?? 'Диспетчер',
    text: json['text'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );

  factory OrderCommentDto.fromFirestore(
    String orderId,
    Map<String, dynamic> data,
  ) => OrderCommentDto(
    orderId: orderId,
    author: data['author'] as String? ?? 'Диспетчер',
    text: data['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  OrderComment toDomain() => OrderComment(
    orderId: orderId,
    author: author,
    text: text,
    createdAt: createdAt,
  );
}
