import 'package:flutter/material.dart';

import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/console_shell.dart';
import 'package:web_console/src/ui/retro.dart';

void main() => runApp(const WebConsoleApp());

class WebConsoleApp extends StatelessWidget {
  const WebConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldPulse · консоль диспетчера',
      debugShowCheckedModeBanner: false,
      theme: retroTheme(),
      home: const ConsolePage(),
    );
  }
}

class ConsolePage extends StatefulWidget {
  const ConsolePage({super.key});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  final List<ConsoleOrder> _orders = demoOrders();
  String? _statusFilter;

  void _selectFilter(String option) {
    setState(() => _statusFilter = option == 'Все' ? null : option);
  }

  @override
  Widget build(BuildContext context) {
    return ConsoleShell(
      metrics: ConsoleMetrics.of(_orders),
      filter: _statusFilter,
      options: statusOptions(_orders),
      orders: sortBySla(filterByStatus(_orders, _statusFilter)),
      onFilterSelected: _selectFilter,
    );
  }
}
