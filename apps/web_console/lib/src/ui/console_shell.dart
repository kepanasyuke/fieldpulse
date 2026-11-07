import 'package:flutter/material.dart';

import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/order_table.dart';
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
    return Scaffold(appBar: _appBar(), body: _body());
  }

  AppBar _appBar() {
    return AppBar(title: const Text('Консоль диспетчера · FieldPulse'));
  }

  Widget _body() {
    return ListView(padding: const EdgeInsets.all(24), children: _sections());
  }

  List<Widget> _sections() {
    return [
      SummaryRow(metrics: metrics),
      const SizedBox(height: 20),
      _filter(),
      const SizedBox(height: 12),
      OrderTable(orders: orders),
    ];
  }

  Widget _filter() {
    return Wrap(spacing: 8, children: _chips());
  }

  List<Widget> _chips() {
    return [for (final option in options) _chip(option)];
  }

  Widget _chip(String option) {
    final selected = (filter ?? 'Все') == option;

    return ChoiceChip(
      label: Text(option),
      selected: selected,
      onSelected: (_) => onFilterSelected(option),
    );
  }
}
