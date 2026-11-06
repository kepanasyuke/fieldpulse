import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporter {
  CrashReporter({FirebaseCrashlytics? crashlytics, this.enabled = true})
    : _crashlytics = crashlytics;

  final FirebaseCrashlytics? _crashlytics;
  final bool enabled;

  void recordUncaught(Object error, StackTrace stack) {
    debugPrint('Uncaught: $error');
    _crashlytics?.recordError(error, stack, fatal: true);
  }

  void recordHandled(Object error, StackTrace stack, {String? reason}) {
    _crashlytics?.recordError(error, stack, reason: reason);
  }

  void log(String message) => _crashlytics?.log(message);

  void setUserId(String? userId) {
    _crashlytics?.setUserIdentifier(userId ?? '');
  }

  void setKey(String key, Object value) {
    _crashlytics?.setCustomKey(key, value.toString());
  }
}
