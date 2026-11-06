import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/push/push_service.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';

class DeviceTokenRegistrar {
  DeviceTokenRegistrar({
    required PushService pushService,
    required AuthRepository auth,
    required CrashReporter crashReporter,
    FirebaseFunctions? functions,
  }) : _pushService = pushService,
       _auth = auth,
       _crashReporter = crashReporter,
       _functions = functions;

  final PushService _pushService;
  final AuthRepository _auth;
  final CrashReporter _crashReporter;
  final FirebaseFunctions? _functions;

  Future<void> register() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final user = _auth.currentUser;
    final token = await _pushService.token();
    if (user == null || token == null) {
      return;
    }

    try {
      final functions = _functions ?? FirebaseFunctions.instance;
      await functions.httpsCallable('registerDeviceToken').call<void>({
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } on FirebaseFunctionsException catch (error, stackTrace) {
      _crashReporter.recordHandled(
        error,
        stackTrace,
        reason: 'Не удалось зарегистрировать push-токен',
      );
    }
  }
}
