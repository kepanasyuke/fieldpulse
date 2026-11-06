import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/push/firebase_background_handler.dart';

class PushService {
  PushService({
    required FirebaseMessaging messaging,
    required CrashReporter crashReporter,
  }) : _messaging = messaging,
       _crashReporter = crashReporter;

  final FirebaseMessaging _messaging;
  final CrashReporter _crashReporter;
  final StreamController<String> _orderDeepLinks =
      StreamController<String>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Stream<String> get orderDeepLinks => _orderDeepLinks.stream;

  Future<bool> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      );

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
        _crashReporter.log('Push в foreground: ${message.messageId}');
      });

      _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _emitOrderLink,
      );

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _emitOrderLink(initial);
      }

      return true;
    } on Exception catch (error, stackTrace) {
      _crashReporter.recordHandled(
        error,
        stackTrace,
        reason: 'Не удалось инициализировать push',
      );
      return false;
    }
  }

  Future<String?> token() async {
    try {
      return await _messaging.getToken();
    } on Exception catch (error) {
      debugPrint('FCM token error: $error');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } on Exception catch (error) {
      debugPrint('FCM subscribe error: $error');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } on Exception catch (error) {
      debugPrint('FCM unsubscribe error: $error');
    }
  }

  void _emitOrderLink(RemoteMessage message) {
    final orderId = message.data['order_id'];
    if (orderId is String && orderId.isNotEmpty && !_orderDeepLinks.isClosed) {
      _orderDeepLinks.add(orderId);
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _orderDeepLinks.close();
  }
}
