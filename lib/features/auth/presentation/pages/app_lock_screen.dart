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
      _scheduleUnlockRequest();
    }
  }

  @override
  void didUpdateWidget(AppLockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.locked && widget.locked) {
      _scheduleUnlockRequest();
    }
  }

  void _scheduleUnlockRequest() {
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
    return const Positioned.fill(child: _LockSurface());
  }
}

class _LockSurface extends StatelessWidget {
  const _LockSurface();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockBloc, AppLockState>(builder: _builder);
  }

  Widget _builder(BuildContext context, AppLockState state) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: _LockBody(state: state),
    );
  }
}

class _LockBody extends StatelessWidget {
  const _LockBody({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: _LockContent(state: state)),
    );
  }
}

class _LockContent extends StatelessWidget {
  const _LockContent({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: _LockColumn(state: state),
    );
  }
}

class _LockColumn extends StatelessWidget {
  const _LockColumn({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: _parts());
  }

  List<Widget> _parts() {
    return [
      const _LockIcon(),
      const SizedBox(height: 16),
      const _LockTitle(),
      const SizedBox(height: 8),
      _LockHint(text: _hint()),
      const SizedBox(height: 24),
      _LockAction(state: state),
      const SizedBox(height: 12),
      const _LockBail(),
    ];
  }

  String _hint() =>
      state.error ?? 'Подтвердите личность, чтобы вернуться к нарядам';
}

class _LockIcon extends StatelessWidget {
  const _LockIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.fingerprint_rounded,
      size: 72,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _LockTitle extends StatelessWidget {
  const _LockTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Приложение заблокировано',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }
}

class _LockHint extends StatelessWidget {
  const _LockHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _LockAction extends StatelessWidget {
  const _LockAction({required this.state});

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return state.isVerifying ? const AdaptiveProgress() : _unlockButton();
  }

  Widget _unlockButton() {
    return FilledButton.icon(
      onPressed: state.canRetry ? () => _unlock(context) : null,
      icon: const Icon(Icons.lock_open_rounded),
      label: Text(_label()),
    );
  }

  void _unlock(BuildContext context) {
    context.read<AppLockBloc>().add(const AppLockUnlockRequested());
  }

  String _label() => state.canRetry ? 'Разблокировать' : 'Попытки исчерпаны';
}

class _LockBail extends StatelessWidget {
  const _LockBail();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _release(context),
      child: const Text('Выйти без биометрии'),
    );
  }

  void _release(BuildContext context) {
    context.read<AppLockBloc>().add(const AppLockReleased());
  }
}
