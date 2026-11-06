import 'package:flutter/widgets.dart';

class LifecycleObserver with WidgetsBindingObserver {
  LifecycleObserver({required this.onBackground});

  final VoidCallback onBackground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      onBackground();
    }
  }
}
