import 'package:flutter/material.dart';

import 'package:fieldpulse/features/orders/domain/entities/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, this.compact = false});

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (foreground, background) = switch (status) {
      OrderStatus.created => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      OrderStatus.assigned => (scheme.onPrimaryContainer, scheme.primaryContainer),
      OrderStatus.inProgress => (scheme.onTertiaryContainer, scheme.tertiaryContainer),
      OrderStatus.done => (scheme.onSecondaryContainer, scheme.secondaryContainer),
      OrderStatus.cancelled => (scheme.onErrorContainer, scheme.errorContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: (compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final OrderPriority priority;

  @override
  Widget build(BuildContext context) {
    if (!priority.isUrgent) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          priority == OrderPriority.critical
              ? Icons.local_fire_department_rounded
              : Icons.priority_high_rounded,
          size: 16,
          color: scheme.error,
        ),
        const SizedBox(width: 2),
        Text(
          priority.label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.error),
        ),
      ],
    );
  }
}
