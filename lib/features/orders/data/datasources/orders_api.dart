import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:fieldpulse/features/orders/data/dto/order_comment_dto.dart';
import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';

part 'orders_api.g.dart';

@RestApi()
abstract class OrdersApi {
  factory OrdersApi(Dio dio, {String baseUrl}) = _OrdersApi;

  @GET('/orders/{id}')
  Future<OrderDto> fetchOrder(@Path('id') String orderId);

  @PATCH('/orders/{id}/status')
  Future<OrderDto> updateStatus(
    @Path('id') String orderId,
    @Body() StatusUpdateDto payload, {
    @Header('Idempotency-Key') required String idempotencyKey,
  });

  @POST('/orders/{id}/photos')
  @MultiPart()
  Future<OrderPhotoDto> uploadPhoto(
    @Path('id') String orderId,
    @Part(name: 'file') File file, {
    @Header('Idempotency-Key') required String idempotencyKey,
  });

  @GET('/orders/{id}/comments')
  Future<List<OrderCommentDto>> fetchComments(@Path('id') String orderId);
}

class StatusUpdateDto {
  const StatusUpdateDto({
    required this.status,
    this.latitude,
    this.longitude,
    this.comment,
  });

  final String status;
  final double? latitude;
  final double? longitude;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'status': status,
    if (latitude != null && longitude != null)
      'check_in': {'lat': latitude, 'lng': longitude},
    if (comment != null) 'comment': comment,
  };
}
