import 'package:fieldpulse/features/orders/data/dto/order_comment_dto.dart';
import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';

class OrderMapper {
  const OrderMapper();

  Order toDomain(OrderDto dto) => Order(
    id: dto.id,
    number: dto.number,
    title: dto.title,
    customer: dto.customer,
    address: dto.address,
    status: OrderStatus.fromWire(dto.status),
    priority: OrderPriority.fromWire(dto.priority),
    updatedAt: dto.updatedAt,
    coordinates: dto.coordinates,
    comment: dto.comment,
    slaDueAt: dto.slaDueAt,
    photos: dto.photos
        .map(
          (photo) => OrderPhoto(
            id: photo.id,
            url: photo.url,
            capturedAt: photo.capturedAt,
          ),
        )
        .toList(growable: false),
  );

  OrderDto toDto(Order order) => OrderDto(
    id: order.id,
    number: order.number,
    title: order.title,
    customer: order.customer,
    address: order.address,
    status: order.status.wire,
    priority: order.priority.wire,
    updatedAt: order.updatedAt,
    slaDueAt: order.slaDueAt,
    coordinates: order.coordinates,
    comment: order.comment,
    photos: order.photos
        .map(
          (photo) => OrderPhotoDto(
            id: photo.id,
            url: photo.url,
            capturedAt: photo.capturedAt,
          ),
        )
        .toList(growable: false),
  );

  OrderComment toDomainComment(OrderCommentDto dto) => dto.toDomain();
}
