import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/app/di/injector.dart';
import 'package:fieldpulse/core/ui/adaptive.dart';
import 'package:fieldpulse/core/utils/date_format.dart';
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
      create: (_) => getIt<OrderDetailsBloc>()
        ..add(OrderDetailsStarted(orderId)),
      child: const _OrderDetailsView(),
    );
  }
}

class _OrderDetailsView extends StatelessWidget {
  const _OrderDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.message != current.message,
      listener: (context, state) {
        final text = state.error?.message ?? state.message;
        if (text == null) {
          return;
        }
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
      },
      builder: (context, state) {
        final order = state.order;
        return Scaffold(
          appBar: AppBar(
            title: Text(order?.number ?? 'Наряд'),
            actions: [
              IconButton(
                tooltip: 'Обновить',
                onPressed: state.isBusy
                    ? null
                    : () => context.read<OrderDetailsBloc>().add(
                        const OrderDetailsRefreshed(),
                      ),
                icon: const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          body: switch (order) {
            null when state.isLoading => const Center(child: AdaptiveProgress()),
            null => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.error?.message ?? 'Наряд не найден в кэше',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            final Order value => _OrderDetailsContent(order: value, state: state),
          },
          bottomNavigationBar: order == null
              ? null
              : _ActionBar(order: order, state: state),
        );
      },
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({required this.order, required this.state});

  final Order order;
  final OrderDetailsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OrderStatusChip(status: order.status),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: order.priority),
                      const Spacer(),
                      if (order.hasPendingUpdate)
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 18,
                          color: scheme.tertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.customer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (order.slaDueAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: order.isOverdue
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SLA: ${AppDateFormat.sla(order.slaDueAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: order.isOverdue
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _SectionCard(
          icon: Icons.place_outlined,
          title: 'Адрес',
          subtitle: order.address,
          trailing: state.checkIn == null
              ? null
              : Text(
                  'Точка: '
                  '${state.checkIn!.latitude.toStringAsFixed(4)}, '
                  '${state.checkIn!.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        if (order.comment != null && order.comment!.isNotEmpty)
          _SectionCard(
            icon: Icons.sticky_note_2_outlined,
            title: 'Комментарий диспетчера',
            subtitle: order.comment!,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Фотоотчёт',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        PhotoStrip(
          photos: order.photos,
          onAdd: state.isBusy
              ? null
              : () => context.read<OrderDetailsBloc>().add(
                  const OrderDetailsPhotoRequested(),
                ),
        ),
        if (order.status.nextSteps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Следующие шаги',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final step in order.status.nextSteps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => context.read<OrderDetailsBloc>().add(
                              OrderDetailsStatusRequested(step),
                            ),
                      icon: Icon(
                        step == OrderStatus.cancelled
                            ? Icons.close_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(step.actionLabel),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Обновлён ${AppDateFormat.dayTime(order.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    if (trailing != null) ...[
                      const SizedBox(height: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: 'Сделать фото',
            onPressed: state.isBusy
                ? null
                : () => context.read<OrderDetailsBloc>().add(
                    const OrderDetailsPhotoRequested(),
                  ),
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: primary == null || state.isBusy
                  ? null
                  : () => context.read<OrderDetailsBloc>().add(
                      OrderDetailsStatusRequested(primary),
                    ),
              child: state.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : Text(
                      primary?.actionLabel ??
                          (order.status.isTerminal ? 'Наряд закрыт' : 'Нет действий'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
