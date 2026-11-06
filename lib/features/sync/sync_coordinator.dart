import 'dart:async';

import 'package:fieldpulse/core/network/network_monitor.dart';
import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';

class SyncCoordinator {
  SyncCoordinator({
    required NetworkMonitor networkMonitor,
    required OrderRepository repository,
    required CrashReporter crashReporter,
    this.retryInterval = const Duration(minutes: 2),
  }) : _networkMonitor = networkMonitor,
       _repository = repository,
       _crashReporter = crashReporter;

  final NetworkMonitor _networkMonitor;
  final OrderRepository _repository;
  final CrashReporter _crashReporter;
  final Duration retryInterval;

  StreamSubscription<bool>? _subscription;
  Timer? _retryTimer;
  bool _online = true;

  Future<void> start() async {
    _online = await _networkMonitor.isOnline();
    _subscription ??= _networkMonitor.onlineChanges.listen(_onConnectivityChanged);
    _retryTimer ??= Timer.periodic(retryInterval, (_) => _flushIfNeeded());
    await _flushIfNeeded();
  }

  Future<void> _onConnectivityChanged(bool online) async {
    final restored = online && !_online;
    _online = online;
    if (!online) {
      return;
    }
    if (restored) {
      _crashReporter.log('Связь восстановлена — отправляю очередь');
    }
    await _flushIfNeeded();
    if (restored) {
      await _repository.fetchOrders(forceRefresh: true);
    }
  }

  Future<void> _flushIfNeeded() async {
    if (!_online) {
      return;
    }
    try {
      await _repository.flushPendingUpdates();
    } on Object catch (error, stackTrace) {
      _crashReporter.recordHandled(
        error,
        stackTrace,
        reason: 'Ошибка синхронизации очереди',
      );
    }
  }

  Future<void> stop() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
