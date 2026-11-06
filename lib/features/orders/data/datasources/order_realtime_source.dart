import 'dart:async';

import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/realtime/realtime_client.dart';
import 'package:fieldpulse/features/orders/data/dto/order_comment_dto.dart';
import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';

class OrderRealtimeSource {
  OrderRealtimeSource({
    required RealtimeClient client,
    required OrderMapper mapper,
    required CrashReporter crashReporter,
  }) : _client = client,
       _mapper = mapper,
       _crashReporter = crashReporter;

  static const Set<String> _ignoredTypes = {'pong', 'presence', 'heartbeat'};

  final RealtimeClient _client;
  final OrderMapper _mapper;
  final CrashReporter _crashReporter;

  Stream<OrderEvent> get events async* {
    await for (final frame in _client.frames) {
      final event = _mapFrame(frame);
      if (event != null) {
        yield event;
      }
    }
  }

  Stream<RealtimeStatus> get connectionStatus => _client.statuses;

  Future<void> connect() => _client.connect();

  Future<void> disconnect() => _client.disconnect();

  Future<void> dispose() => _client.dispose();

  String get url => _client.url;

  OrderEvent? _mapFrame(Map<String, dynamic> frame) {
    final type = frame['type'];
    if (type is! String || _ignoredTypes.contains(type)) {
      return null;
    }
    final payload = frame['payload'];

    try {
      return _eventFor(type, payload, frame);
    } on Object catch (error, stackTrace) {
      _crashReporter.recordHandled(
        error,
        stackTrace,
        reason: 'Не удалось разобрать realtime-кадр $type',
      );
      return null;
    }
  }

  OrderEvent? _eventFor(
    String type,
    Object? payload,
    Map<String, dynamic> frame,
  ) {
    return switch (type) {
      'orders.snapshot' => _snapshot(payload),
      'order.upserted' => _upserted(payload, frame),
      'order.removed' => _removed(payload),
      'order.comment' => _comment(payload),
      'connection' => _connection(payload),
      _ => null,
    };
  }

  OrderEvent? _snapshot(Object? payload) {
    return payload is List ? OrdersSnapshotEvent(_orders(payload)) : null;
  }

  List<Order> _orders(List<dynamic> payload) {
    return payload
        .whereType<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .map(_mapper.toDomain)
        .toList(growable: false);
  }

  OrderEvent? _upserted(Object? payload, Map<String, dynamic> frame) {
    final dto = _orderDto(payload);
    final isValid = dto != null && dto.id.isNotEmpty;

    return isValid
        ? OrderUpsertedEvent(
            _mapper.toDomain(dto),
            reason: frame['reason'] as String?,
          )
        : null;
  }

  OrderEvent? _removed(Object? payload) {
    final orderId = payload is Map ? payload['id'] : null;

    return orderId is String ? OrderRemovedEvent(orderId) : null;
  }

  OrderEvent? _comment(Object? payload) {
    final dto = payload is Map
        ? OrderCommentDto.fromJson(Map<String, dynamic>.from(payload))
        : null;
    final isValid = dto != null && dto.orderId.isNotEmpty;

    return isValid ? OrderCommentEvent(_mapper.toDomainComment(dto)) : null;
  }

  OrderEvent? _connection(Object? payload) {
    final online = payload is Map && payload['online'] == true;

    return OrderConnectionEvent(online: online);
  }

  OrderDto? _orderDto(Object? payload) {
    return payload is Map
        ? OrderDto.fromJson(Map<String, dynamic>.from(payload))
        : null;
  }
}
