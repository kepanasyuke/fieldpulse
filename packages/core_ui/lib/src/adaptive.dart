import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension AdaptiveContext on BuildContext {
  TargetPlatform get _platform => Theme.of(this).platform;

  bool get isCupertinoPlatform =>
      _platform == TargetPlatform.iOS || _platform == TargetPlatform.macOS;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => screenWidth < 600;

  bool get isTablet => screenWidth >= 900;

  T adaptive<T>({required T material, required T cupertino}) =>
      isCupertinoPlatform ? cupertino : material;

  Future<bool> showAdaptiveConfirm({
    required String title,
    required String message,
    String confirmLabel = 'Подтвердить',
    String cancelLabel = 'Отмена',
  }) async {
    if (isCupertinoPlatform) {
      return await showCupertinoDialog<bool>(
            context: this,
            builder: (dialogContext) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(cancelLabel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ) ??
          false;
    }

    return await showDialog<bool>(
          context: this,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class AdaptiveProgress extends StatelessWidget {
  const AdaptiveProgress({super.key});

  @override
  Widget build(BuildContext context) => context.adaptive(
    material: const CircularProgressIndicator.adaptive(),
    cupertino: const CupertinoActivityIndicator(),
  );
}
