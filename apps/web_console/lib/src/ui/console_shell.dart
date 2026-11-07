import 'package:flutter/material.dart';

import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/order_table.dart';
import 'package:web_console/src/ui/retro.dart';
import 'package:web_console/src/ui/summary_row.dart';

class ConsoleShell extends StatelessWidget {
  const ConsoleShell({
    super.key,
    required this.metrics,
    required this.filter,
    required this.options,
    required this.orders,
    required this.onFilterSelected,
  });

  final ConsoleMetrics metrics;
  final String? filter;
  final List<String> options;
  final List<ConsoleOrder> orders;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: _desktop()));
  }

  Widget _desktop() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: _window(),
      ),
    );
  }

  Widget _window() {
    return RetroWindow(
      title: 'FieldPulse — консоль диспетчера',
      child: _content(),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisSize: MainAxisSize.min, children: _sections()),
    );
  }

  List<Widget> _sections() {
    return [
      SummaryRow(metrics: metrics),
      const SizedBox(height: 10),
      _toolbar(),
      const SizedBox(height: 10),
      RetroPanel(padding: 4, child: OrderTable(orders: orders)),
      const SizedBox(height: 10),
      _statusBar(),
    ];
  }

  Widget _toolbar() {
    return RetroPanel(
      padding: 8,
      child: Wrap(spacing: 6, runSpacing: 6, children: _chips()),
    );
  }

  List<Widget> _chips() {
    return [for (final option in options) _chip(option)];
  }

  Widget _chip(String option) {
    return RetroButton(
      label: option,
      icon: 'folder.svg',
      selected: (filter ?? 'Все') == option,
      onPressed: () => onFilterSelected(option),
    );
  }

  Widget _statusBar() {
    return RetroPanel(padding: 6, child: Row(children: _statusItems()));
  }

  List<Widget> _statusItems() {
    return [
      const RetroIcon('monitor.svg', size: 12),
      const SizedBox(width: 6),
      Expanded(child: _statusText()),
      Text('нарядов: ${orders.length}'),
    ];
  }

  Widget _statusText() {
    return Text('Готово · просрочено: ${metrics.overdue}');
  }
}
