import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/core/ui/adaptive.dart';
import 'package:fieldpulse/features/auth/presentation/bloc/app_lock_bloc.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestUnlock());
    }
  }

  @override
  void didUpdateWidget(AppLockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.locked && widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestUnlock());
    }
  }

  void _requestUnlock() {
    if (!mounted) {
      return;
    }
    context.read<AppLockBloc>().add(const AppLockUnlockRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.locked)
          Positioned.fill(
            child: BlocBuilder<AppLockBloc, AppLockState>(
              builder: (context, state) => ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Приложение заблокировано',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error ??
                                'Подтвердите личность, чтобы вернуться к нарядам',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (state.isVerifying)
                            const AdaptiveProgress()
                          else
                            FilledButton.icon(
                              onPressed: state.canRetry ? _requestUnlock : null,
                              icon: const Icon(Icons.lock_open_rounded),
                              label: Text(
                                state.canRetry
                                    ? 'Разблокировать'
                                    : 'Попытки исчерпаны',
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.read<AppLockBloc>().add(
                              const AppLockReleased(),
                            ),
                            child: const Text('Выйти без биометрии'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
