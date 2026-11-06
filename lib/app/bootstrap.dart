import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fieldpulse/app/app.dart';
import 'package:fieldpulse/app/di/injector.dart';
import 'package:fieldpulse/core/config/app_config.dart';
import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/push/device_token_registrar.dart';
import 'package:fieldpulse/core/push/push_service.dart';
import 'package:fieldpulse/features/sync/sync_coordinator.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru');
  final firebaseReady = await _initFirebase();
  await Hive.initFlutter();

  await configureDependencies(
    config: AppConfig.fromEnvironment.copyWith(enableNetworkLogs: kDebugMode),
    firebaseReady: firebaseReady,
  );

  await getIt<SyncCoordinator>().start();
  if (getIt.isRegistered<PushService>()) {
    await getIt<PushService>().initialize();
    await getIt<DeviceTokenRegistrar>().register();
  }

  runZonedGuarded(
    () => runApp(const FieldPulseApp()),
    (error, stack) => getIt<CrashReporter>().recordUncaught(error, stack),
  );
}

Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
  } on Exception catch (error) {
    debugPrint('Firebase не сконфигурирован, работаем в offline-режиме: $error');
    return false;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  return true;
}
