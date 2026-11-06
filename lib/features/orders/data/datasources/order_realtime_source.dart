import 'dart:async';

import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/realtime/realtime_client.dart';
import 'package:fieldpulse/features/orders/data/dto/order_comment_dto.dart';
import 'package:fieldpulse/features/orders/data/dto/order_dto.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
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
      switch (type) {
        case 'orders.snapshot':
          if (payload is! List) {
            return null;
          }
          final orders = payload
              .whereType<Map<String, dynamic>>()
              .map(OrderDto.fromJson)
              .map(_mapper.toDomain)
              .toList(growable: false);
          return OrdersSnapshotEvent(orders);

        case 'order.upserted':
          if (payload is! Map) {
            return null;
          }
          final dto = OrderDto.fromJson(Map<String, dynamic>.from(payload));
          if (dto.id.isEmpty) {
            return null;
          }
          return OrderUpsertedEvent(
            _mapper.toDomain(dto),
            reason: frame['reason'] as String?,
          );

        case 'order.removed':
          if (payload is! Map) {
            return null;
          }
          final orderId = payload['id'];
          return orderId is String ? OrderRemovedEvent(orderId) : null;

        case 'order.comment':
          if (payload is! Map) {
            return null;
          }
          final dto = OrderCommentDto.fromJson(
            Map<String, dynamic>.from(payload),
          );
          return dto.orderId.isEmpty
              ? null
              : OrderCommentEvent(_mapper.toDomainComment(dto));

        case 'connection':
          final online = payload is Map && payload['online'] == true;
          return OrderConnectionEvent(online: online);

        default:
          return null;
      }
    } on Object catch (error, stackTrace) {
      _crashReporter.recordHandled(
        error,
        stackTrace,
        reason: 'Не удалось разобрать realtime-кадр $type',
      );
      return null;
    }
  }
}
