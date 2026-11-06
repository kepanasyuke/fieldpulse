import 'dart:convert';

import 'package:fieldpulse/core/isolates/payload_decoder.dart';
import 'package:fieldpulse/core/network/api_client.dart';
import 'package:fieldpulse/core/network/dio_failure_mapper.dart';
import 'package:core_network/core_network.dart';
import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';

class OrderListRemoteSource {
  OrderListRemoteSource({
    required ApiClient apiClient,
    required PayloadDecoder decoder,
  }) : _apiClient = apiClient,
       _decoder = decoder;

  final ApiClient _apiClient;
  final PayloadDecoder _decoder;

  Future<Result<List<OrderDto>>> fetch({int limit = 100}) async {
    try {
      final response = await _apiClient.getJson<String>(
        '/orders',
        queryParameters: {'limit': limit, 'include': 'photos'},
      );
      final body = response.data ?? '[]';
      final orders = await _decoder.decode(body, _parseOrders);
      return Ok(orders);
    } on Object catch (error) {
      return Err(error.toFailure());
    }
  }

  static List<OrderDto> _parseOrders(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .where((dto) => dto.id.isNotEmpty)
        .toList(growable: false);
  }
}
