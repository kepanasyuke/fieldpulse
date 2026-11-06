import 'package:flutter/material.dart';

import 'package:fieldpulse/core/utils/date_format.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/order_status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PriorityBadge(priority: order.priority),
                  const SizedBox(width: 6),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: order.isOverdue ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.slaDueAt != null
                        ? AppDateFormat.sla(order.slaDueAt!)
                        : AppDateFormat.relative(order.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: order.isOverdue
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (order.photos.isNotEmpty) ...[
                    Icon(
                      Icons.photo_camera_back_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order.photos.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (order.hasPendingUpdate)
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: scheme.tertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
