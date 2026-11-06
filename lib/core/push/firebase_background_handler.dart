import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on Exception catch (error) {
    debugPrint('Background isolate без Firebase: $error');
    return;
  }
  debugPrint(
    'Фоновое уведомление ${message.messageId}: '
    '${message.notification?.title ?? message.data['title']}',
  );
}
