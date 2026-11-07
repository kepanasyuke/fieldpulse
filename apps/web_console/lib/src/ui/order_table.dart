import 'package:flutter/material.dart';

import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/retro.dart';

class OrderTable extends StatelessWidget {
  const OrderTable({super.key, required this.orders});

  final List<ConsoleOrder> orders;

  @override
  Widget build(BuildContext context) {
    return RetroPanel(padding: 0, child: _table());
  }

  Widget _table() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: _columns(), rows: _rows()),
    );
  }

  List<DataColumn> _columns() {
    return const [
      DataColumn(label: Text('Наряд')),
      DataColumn(label: Text('Клиент')),
      DataColumn(label: Text('Статус')),
      DataColumn(label: Text('SLA')),
    ];
  }

  List<DataRow> _rows() {
    return [for (final order in orders) _row(order)];
  }

  DataRow _row(ConsoleOrder order) {
    return DataRow(
      cells: [
        DataCell(Text(order.number)),
        DataCell(Text(order.client)),
        DataCell(StatusChip(status: order.status)),
        DataCell(SlaText(order: order)),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: retroBevel(inset: true),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(status, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class SlaText extends StatelessWidget {
  const SlaText({super.key, required this.order});

  final ConsoleOrder order;

  @override
  Widget build(BuildContext context) {
    return Text(order.slaLabel, style: TextStyle(color: _color(context)));
  }

  Color? _color(BuildContext context) {
    return order.isOverdue ? Theme.of(context).colorScheme.error : null;
  }
}
