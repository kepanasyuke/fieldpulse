import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/app/di/injector.dart';
import 'package:core_ui/core_ui.dart';
import 'package:fieldpulse/core/utils/date_format.dart';
import 'package:fieldpulse/core/models/coordinates.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/presentation/bloc/order_details_bloc.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/photo_strip.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderDetailsBloc>(
      create: (_) =>
          getIt<OrderDetailsBloc>()..add(OrderDetailsStarted(orderId)),
      child: const _OrderDetailsView(),
    );
  }
}

class _OrderDetailsView extends StatelessWidget {
  const _OrderDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
      listenWhen: _hasNewFeedback,
      listener: _showFeedback,
      builder: _buildScaffold,
    );
  }

  bool _hasNewFeedback(OrderDetailsState previous, OrderDetailsState current) =>
      previous.error != current.error || previous.message != current.message;

  void _showFeedback(BuildContext context, OrderDetailsState state) {
    final text = state.error?.message ?? state.message;
    if (text != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            backgroundColor: state.error == null
                ? null
                : Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  Widget _buildScaffold(BuildContext context, OrderDetailsState state) {
    return Scaffold(
      appBar: _buildAppBar(context, state),
      body: _buildBody(state),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  AppBar _buildAppBar(BuildContext context, OrderDetailsState state) {
    return AppBar(
      title: Text(state.order?.number ?? 'Наряд'),
      actions: [
        IconButton(
          tooltip: 'Обновить',
          onPressed: state.isBusy ? null : () => _refresh(context),
          icon: const Icon(Icons.sync_rounded),
        ),
      ],
    );
  }

  void _refresh(BuildContext context) =>
      context.read<OrderDetailsBloc>().add(const OrderDetailsRefreshed());

  Widget _buildBody(OrderDetailsState state) {
    return switch (state.order) {
      null when state.isLoading => const Center(child: AdaptiveProgress()),
      null => _NotFound(
        message: state.error?.message ?? 'Наряд не найден в кэше',
      ),
      final Order order => _OrderDetailsContent(order: order, state: state),
    };
  }

  Widget? _buildBottomBar(OrderDetailsState state) {
    final order = state.order;
    return order == null ? null : _ActionBar(order: order, state: state);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({required this.order, required this.state});

  final Order order;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _HeaderCard(order: order),
        _SectionCard(
          icon: Icons.place_outlined,
          title: 'Адрес',
          subtitle: order.address,
          trailing: _checkInText(context, state.checkIn),
        ),
        if (order.comment != null && order.comment!.isNotEmpty)
          _SectionCard(
            icon: Icons.sticky_note_2_outlined,
            title: 'Комментарий диспетчера',
            subtitle: order.comment!,
          ),
        _PhotosSection(order: order, state: state),
        _NextStepsSection(order: order, state: state),
        _UpdatedLabel(order: order),
      ],
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.order, required this.state});

  final Order order;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parts(context),
    );
  }

  List<Widget> _parts(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: _caption(context),
      ),
      PhotoStrip(photos: order.photos, onAdd: _onAdd(context)),
    ];
  }

  Widget _caption(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Фотоотчёт',
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  VoidCallback? _onAdd(BuildContext context) {
    return state.isBusy ? null : () => _requestPhoto(context);
  }

  void _requestPhoto(BuildContext context) {
    context.read<OrderDetailsBloc>().add(const OrderDetailsPhotoRequested());
  }
}

class _NextStepsSection extends StatelessWidget {
  const _NextStepsSection({required this.order, required this.state});

  final Order order;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return order.status.nextSteps.isEmpty
        ? const SizedBox.shrink()
        : _section(context);
  }

  Widget _section(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parts(context),
      ),
    );
  }

  List<Widget> _parts(BuildContext context) {
    return [
      _caption(context),
      const SizedBox(height: 8),
      for (final step in order.status.nextSteps)
        _StepButton(step: step, state: state),
    ];
  }

  Widget _caption(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Следующие шаги',
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.step, required this.state});

  final OrderStatus step;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _button(context),
    );
  }

  Widget _button(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: state.isBusy ? null : () => _request(context),
      icon: Icon(_icon),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(step.actionLabel),
      ),
    );
  }

  void _request(BuildContext context) {
    context.read<OrderDetailsBloc>().add(OrderDetailsStatusRequested(step));
  }

  IconData get _icon => step == OrderStatus.cancelled
      ? Icons.close_rounded
      : Icons.arrow_forward_rounded;
}

class _UpdatedLabel extends StatelessWidget {
  const _UpdatedLabel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(_label(), style: _style(context)),
    );
  }

  String _label() => 'Обновлён ${AppDateFormat.dayTime(order.updatedAt)}';

  TextStyle? _style(BuildContext context) {
    final theme = Theme.of(context);

    return theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: _SectionBody(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _SectionRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: _SectionTexts(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
        ),
      ],
    );
  }
}

class _SectionTexts extends StatelessWidget {
  const _SectionTexts({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parts(context),
    );
  }

  List<Widget> _parts(BuildContext context) {
    return [
      _title(context),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      if (trailing != null) const SizedBox(height: 6),
      if (trailing != null) trailing!,
    ];
  }

  Widget _title(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Text(title, style: style);
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order, required this.state});

  final Order order;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    final steps = order.status.nextSteps
        .where((status) => status != OrderStatus.cancelled)
        .toList(growable: false);
    final primary = steps.isEmpty ? null : steps.first;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(children: _items(context, primary)),
    );
  }

  List<Widget> _items(BuildContext context, OrderStatus? primary) {
    return [
      _CameraButton(state: state),
      const SizedBox(width: 12),
      Expanded(
        child: _PrimaryButton(state: state, order: order, primary: primary),
      ),
    ];
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.state});

  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: 'Сделать фото',
      onPressed: state.isBusy ? null : () => _request(context),
      icon: const Icon(Icons.photo_camera_outlined),
    );
  }

  void _request(BuildContext context) {
    context.read<OrderDetailsBloc>().add(const OrderDetailsPhotoRequested());
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.state,
    required this.order,
    required this.primary,
  });

  final OrderDetailsState state;
  final Order order;
  final OrderStatus? primary;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _canPress ? () => _request(context) : null,
      child: state.isBusy ? const _BusyLabel() : Text(_label),
    );
  }

  bool get _canPress => primary != null && !state.isBusy;

  String get _label => primary?.actionLabel ?? _fallback;

  String get _fallback =>
      order.status.isTerminal ? 'Наряд закрыт' : 'Нет действий';

  void _request(BuildContext context) {
    context.read<OrderDetailsBloc>().add(OrderDetailsStatusRequested(primary!));
  }
}

class _BusyLabel extends StatelessWidget {
  const _BusyLabel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
    );
  }
}

Widget? _checkInText(BuildContext context, Coordinates? checkIn) {
  if (checkIn == null) {
    return null;
  }
  final theme = Theme.of(context);
  final label =
      'Точка: ${checkIn.latitude.toStringAsFixed(4)}, '
      '${checkIn.longitude.toStringAsFixed(4)}';

  return Text(
    label,
    style: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: _column(context));
  }

  Widget _column(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parts(context),
    );
  }

  List<Widget> _parts(BuildContext context) {
    return [
      _topRow(context),
      const SizedBox(height: 12),
      _title(context),
      const SizedBox(height: 8),
      _customer(context),
      if (order.slaDueAt != null) _slaRow(context),
    ];
  }

  Widget _topRow(BuildContext context) {
    return Row(children: _topItems(context));
  }

  List<Widget> _topItems(BuildContext context) {
    return [
      OrderStatusChip(status: order.status),
      const SizedBox(width: 8),
      PriorityBadge(priority: order.priority),
      const Spacer(),
      if (order.hasPendingUpdate) _pendingIcon(context),
    ];
  }

  Widget _pendingIcon(BuildContext context) {
    return Icon(
      Icons.cloud_upload_outlined,
      size: 18,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _title(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    return Text(order.title, style: style);
  }

  Widget _customer(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Text(order.customer, style: style);
  }

  Widget _slaRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: _slaItems(context)),
    );
  }

  List<Widget> _slaItems(BuildContext context) {
    return [
      Icon(_slaIcon, size: 16, color: _slaColor(context)),
      const SizedBox(width: 6),
      Text(_slaLabel(), style: _slaStyle(context)),
    ];
  }

  IconData get _slaIcon => Icons.timer_outlined;

  String _slaLabel() => 'SLA: ${AppDateFormat.sla(order.slaDueAt!)}';

  TextStyle? _slaStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: _slaColor(context));
  }

  Color _slaColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return order.isOverdue ? scheme.error : scheme.onSurfaceVariant;
  }
}
