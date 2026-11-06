import 'package:flutter/material.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.pendingCount,
    this.onSyncPressed,
    this.isSyncing = false,
  });

  final int pendingCount;
  final VoidCallback? onSyncPressed;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (isSyncing)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            else
              Icon(Icons.cloud_off_rounded, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pendingCount == 1
                    ? '1 изменение ждёт отправки'
                    : '$pendingCount изменений ждут отправки',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
            if (onSyncPressed != null)
              TextButton(
                onPressed: isSyncing ? null : onSyncPressed,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onTertiaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Отправить'),
              ),
          ],
        ),
      ),
    );
  }
}
