import 'dart:async';
import 'dart:io';

import 'package:fieldpulse/core/config/app_config.dart';
import 'package:core_network/core_network.dart';
import 'package:fieldpulse/core/models/coordinates.dart';
import 'package:fieldpulse/core/network/network_monitor.dart';
import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:core_storage/core_storage.dart';
import 'package:fieldpulse/core/utils/id_generator.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_list_remote_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_local_data_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_realtime_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/orders_api.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
import 'package:fieldpulse/features/orders/data/outbox/pending_action.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/entities/order_event.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';

class OrdersRepositoryImpl implements OrderRepository {
  OrdersRepositoryImpl({
    required OrdersApi api,
    required OrderListRemoteSource listRemote,
    required OrderLocalDataSource local,
    required OrderRealtimeSource realtime,
    required OrderMapper mapper,
    required NetworkMonitor networkMonitor,
    required SettingsStore settings,
    required CrashReporter crashReporter,
    required AppConfig config,
  }) : _api = api,
       _listRemote = listRemote,
       _local = local,
       _realtime = realtime,
       _mapper = mapper,
       _networkMonitor = networkMonitor,
       _settings = settings,
       _crashReporter = crashReporter,
       _config = config;

  final OrdersApi _api;
  final OrderListRemoteSource _listRemote;
  final OrderLocalDataSource _local;
  final OrderRealtimeSource _realtime;
  final OrderMapper _mapper;
  final NetworkMonitor _networkMonitor;
  final SettingsStore _settings;
  final CrashReporter _crashReporter;
  final AppConfig _config;

  final StreamController<OrderEvent> _events =
      StreamController<OrderEvent>.broadcast();
  StreamSubscription<OrderEvent>? _realtimeSubscription;
  bool _flushing = false;

  @override
  Stream<OrderEvent> watchEvents() {
    _ensureRealtime();
    return _events.stream;
  }

  void _ensureRealtime() {
    if (_realtimeSubscription != null) {
      return;
    }
    _realtimeSubscription = _realtime.events.listen((event) {
      unawaited(_apply(event));
      if (!_events.isClosed) {
        _events.add(event);
      }
    });
    unawaited(_realtime.connect());
  }

  Future<void> _apply(OrderEvent event) async {
    switch (event) {
      case OrdersSnapshotEvent(:final orders):
        await _local.saveOrders(orders);
        await _settings.markSynced();
      case OrderUpsertedEvent(:final order):
        await _local.upsert(order);
      case OrderRemovedEvent(:final orderId):
        await _local.remove(orderId);
      case OrderCommentEvent():
      case OrderConnectionEvent():
        break;
    }
  }

  @override
  Future<Result<List<Order>>> fetchOrders({bool forceRefresh = false}) async {
    final cached = _local.readOrders();
    if (!forceRefresh && cached.isNotEmpty && _isCacheFresh()) {
      return Ok(cached);
    }

    final result = await _listRemote.fetch();
    final failure = result.failureOrNull;
    if (failure != null) {
      return cached.isNotEmpty ? Ok(cached) : Err(failure);
    }

    final dtos = result.valueOrNull ?? const [];
    await _local.saveOrders(dtos.map(_mapper.toDomain).toList(growable: false));
    await _settings.markSynced();
    return Ok(_local.readOrders());
  }

  @override
  Future<Result<Order>> fetchOrder(String orderId) async {
    try {
      final dto = await _api.fetchOrder(orderId);
      await _local.upsert(_mapper.toDomain(dto));
      final cached = _local.findById(orderId);
      return cached != null ? Ok(cached) : Err(const CacheFailure());
    } on Object catch (error) {
      final cached = _local.findById(orderId);
      return cached != null ? Ok(cached) : Err(error.toFailure());
    }
  }

  @override
  Stream<List<Order>> watchCachedOrders() =>
      _local.watchOrders().distinct(OrderLocalDataSource.sameOrders);

  @override
  Stream<int> watchPendingUpdatesCount() =>
      _local.watchPendingCount().distinct();

  @override
  Future<Result<void>> changeStatus({
    required String orderId,
    required OrderStatus status,
    Coordinates? checkIn,
  }) async {
    final requestId = newRequestId();
    final online = await _networkMonitor.isOnline();
    if (!online) {
      await _queueStatus(orderId, status, checkIn, requestId);
      return const Ok<void>(null);
    }

    try {
      final dto = await _api.updateStatus(
        orderId,
        StatusUpdateDto(
          status: status.wire,
          latitude: checkIn?.latitude,
          longitude: checkIn?.longitude,
        ),
        idempotencyKey: requestId,
      );
      await _local.upsert(_mapper.toDomain(dto));
      return const Ok<void>(null);
    } on Object catch (error) {
      final failure = error.toFailure();
      if (_isRetryable(failure)) {
        await _queueStatus(orderId, status, checkIn, requestId);
        return const Ok<void>(null);
      }
      return Err(failure);
    }
  }

  @override
  Future<Result<void>> attachPhoto({
    required String orderId,
    required String filePath,
  }) async {
    final requestId = newRequestId();
    final online = await _networkMonitor.isOnline();
    if (!online) {
      await _queuePhoto(orderId, filePath, requestId);
      return const Ok<void>(null);
    }

    try {
      final photo = await _api.uploadPhoto(
        orderId,
        File(filePath),
        idempotencyKey: requestId,
      );
      await _appendPhoto(orderId, photo.id, photo.url, photo.capturedAt);
      return const Ok<void>(null);
    } on Object catch (error) {
      final failure = error.toFailure();
      if (_isRetryable(failure)) {
        await _queuePhoto(orderId, filePath, requestId);
        return const Ok<void>(null);
      }
      return Err(failure);
    }
  }

  @override
  Future<void> flushPendingUpdates() async {
    if (!_flushing) {
      _flushing = true;
      try {
        await _flushLoop();
      } finally {
        _flushing = false;
      }
    }
  }

  Future<void> _flushLoop() async {
    for (final action in _local.readPendingActions()) {
      final sent = await _send(action);
      if (!sent) {
        break;
      }
      await _local.dropPending(action.id);
      await _refreshPendingFlag(action.orderId);
    }
  }

  Future<void> _refreshPendingFlag(String orderId) async {
    final cached = _local.findById(orderId);
    if (cached == null) {
      return;
    }
    final hasPending = _local.readPendingActions().any(
      (action) => action.orderId == orderId,
    );
    await _local.upsert(cached.copyWith(hasPendingUpdate: hasPending));
  }

  Future<bool> _send(PendingAction action) async {
    switch (action.type) {
      case PendingActionType.status:
        final status = action.orderStatus;
        if (status == null) {
          return true;
        }
        try {
          final dto = await _api.updateStatus(
            action.orderId,
            StatusUpdateDto(
              status: status.wire,
              latitude: action.latitude,
              longitude: action.longitude,
            ),
            idempotencyKey: action.id,
          );
          await _local.upsert(_mapper.toDomain(dto));
          return true;
        } on Object catch (error) {
          return _handleSyncError(error, action);
        }

      case PendingActionType.photo:
        final path = action.filePath;
        if (path == null) {
          return true;
        }
        try {
          final photo = await _api.uploadPhoto(
            action.orderId,
            File(path),
            idempotencyKey: action.id,
          );
          await _appendPhoto(
            action.orderId,
            photo.id,
            photo.url,
            photo.capturedAt,
          );
          return true;
        } on Object catch (error) {
          return _handleSyncError(error, action);
        }
    }
  }

  bool _handleSyncError(Object error, PendingAction action) {
    final failure = error.toFailure();
    if (_isRetryable(failure)) {
      return false;
    }
    _crashReporter.recordHandled(
      error,
      StackTrace.current,
      reason: 'Отброшено действие ${action.type.name} по ${action.orderId}',
    );
    return true;
  }

  Future<void> _queueStatus(
    String orderId,
    OrderStatus status,
    Coordinates? checkIn,
    String requestId,
  ) async {
    final cached = _local.findById(orderId);
    if (cached != null) {
      await _local.upsert(
        cached.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          hasPendingUpdate: true,
        ),
      );
    }
    await _local.enqueue(
      PendingAction(
        id: requestId,
        orderId: orderId,
        type: PendingActionType.status,
        createdAt: DateTime.now(),
        status: status.wire,
        latitude: checkIn?.latitude,
        longitude: checkIn?.longitude,
      ),
    );
  }

  Future<void> _queuePhoto(
    String orderId,
    String filePath,
    String requestId,
  ) async {
    final cached = _local.findById(orderId);
    if (cached != null) {
      await _local.upsert(
        cached.copyWith(
          updatedAt: DateTime.now(),
          hasPendingUpdate: true,
          photos: [
            ...cached.photos,
            OrderPhoto(
              id: requestId,
              url: '',
              capturedAt: DateTime.now(),
              localPath: filePath,
            ),
          ],
        ),
      );
    }
    await _local.enqueue(
      PendingAction(
        id: requestId,
        orderId: orderId,
        type: PendingActionType.photo,
        createdAt: DateTime.now(),
        filePath: filePath,
      ),
    );
  }

  Future<void> _appendPhoto(
    String orderId,
    String photoId,
    String url,
    DateTime capturedAt,
  ) async {
    final cached = _local.findById(orderId);
    if (cached == null) {
      return;
    }
    final photos = [...cached.photos];
    final placeholderIndex = photos.indexWhere((photo) => !photo.isUploaded);
    if (placeholderIndex >= 0) {
      photos.removeAt(placeholderIndex);
    }
    await _local.upsert(
      cached.copyWith(
        updatedAt: capturedAt,
        photos: [
          ...photos,
          OrderPhoto(id: photoId, url: url, capturedAt: capturedAt),
        ],
      ),
    );
  }

  bool _isRetryable(Failure failure) => switch (failure) {
    NetworkFailure() || TimeoutFailure() => true,
    ServerFailure(:final statusCode) => statusCode >= 500,
    _ => false,
  };

  bool _isCacheFresh() {
    final lastSync = _settings.lastSyncAt;
    return lastSync != null &&
        DateTime.now().difference(lastSync) < _config.cacheTtl;
  }

  Future<void> dispose() async {
    await _realtimeSubscription?.cancel();
    await _realtime.dispose();
    await _events.close();
  }
}
