import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core_ui/core_ui.dart';
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
      _requestUnlockAfterFrame();
    }
  }

  @override
  void didUpdateWidget(AppLockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.locked && widget.locked) {
      _requestUnlockAfterFrame();
    }
  }

  void _requestUnlockAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestUnlock());
  }

  void _requestUnlock() {
    if (mounted) {
      context.read<AppLockBloc>().add(const AppLockUnlockRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _layers());
  }

  List<Widget> _layers() {
    return [widget.child, if (widget.locked) const _LockOverlay()];
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: _overlay(context));
  }

  Widget _overlay(BuildContext context) {
    return BlocBuilder<AppLockBloc, AppLockState>(builder: _buildLock);
  }

  Widget _buildLock(BuildContext context, AppLockState state) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(child: _LockCard(state: state)),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _LockColumn(state: state),
      ),
    );
  }
}

class _LockColumn extends StatelessWidget {
  const _LockColumn({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: _parts(context));
  }

  List<Widget> _parts(BuildContext context) {
    return [
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
      _LockHint(state: state),
      const SizedBox(height: 24),
      _UnlockAction(state: state),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () =>
            context.read<AppLockBloc>().add(const AppLockReleased()),
        child: const Text('Выйти без биометрии'),
      ),
    ];
  }
}

class _LockHint extends StatelessWidget {
  const _LockHint({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    final message =
        state.error ?? 'Подтвердите личность, чтобы вернуться к нарядам';

    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _UnlockAction extends StatelessWidget {
  const _UnlockAction({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return state.isVerifying
        ? const AdaptiveProgress()
        : _UnlockButton(state: state);
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: state.canRetry ? _unlock(context) : null,
      icon: const Icon(Icons.lock_open_rounded),
      label: Text(state.canRetry ? 'Разблокировать' : 'Попытки исчерпаны'),
    );
  }

  VoidCallback _unlock(BuildContext context) {
    return () =>
        context.read<AppLockBloc>().add(const AppLockUnlockRequested());
  }
}
