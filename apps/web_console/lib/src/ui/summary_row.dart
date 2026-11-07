import 'package:flutter/material.dart';

import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/retro.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.metrics});

  final ConsoleMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: _cards());
  }

  List<Widget> _cards() {
    return [
      MetricCard(label: 'Всего нарядов', value: '${metrics.total}'),
      MetricCard(label: 'В работе', value: '${metrics.inProgress}'),
      MetricCard(
        label: 'Просрочено',
        value: '${metrics.overdue}',
        isAlert: true,
      ),
    ];
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 220, child: _card(context));
  }

  Widget _card(BuildContext context) {
    return RetroPanel(child: _texts(context));
  }

  Widget _body(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: _texts(context));
  }

  Widget _texts(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: _color(theme)),
        ),
      ],
    );
  }

  Color? _color(ThemeData theme) {
    return isAlert ? theme.colorScheme.error : null;
  }
}
