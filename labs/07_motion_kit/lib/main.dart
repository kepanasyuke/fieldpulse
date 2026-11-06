import 'package:flutter/material.dart';

import 'package:lab_motion_kit/src/ui/motion_cards.dart';

void main() => runApp(const MotionKitApp());

class MotionKitApp extends StatelessWidget {
  const MotionKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 07 · Motion kit',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: const MotionPage(),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
    );
  }
}

class MotionPage extends StatefulWidget {
  const MotionPage({super.key});

  @override
  State<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<MotionPage> {
  bool _expanded = false;
  int _pulseKey = 0;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  void _restart() => setState(() => _pulseKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Анимации')),
      body: _body(),
    );
  }

  Widget _body() {
    return ListView(padding: const EdgeInsets.all(16), children: _sections());
  }

  List<Widget> _sections() {
    return [
      CounterCard(key: ValueKey<int>(_pulseKey)),
      const SizedBox(height: 12),
      ExpandingCard(expanded: _expanded, onToggle: _toggleExpanded),
      const SizedBox(height: 12),
      const StaggeredList(count: 3),
      const SizedBox(height: 16),
      FilledButton.tonal(
        onPressed: _restart,
        child: const Text('Перезапустить анимации'),
      ),
    ];
  }
}
