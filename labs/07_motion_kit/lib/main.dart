import 'package:flutter/material.dart';

import 'package:lab_motion_kit/src/motion.dart';

void main() => runApp(const MotionKitApp());

class MotionKitApp extends StatelessWidget {
  const MotionKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 07 · Motion kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const MotionPage(),
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

  void _restartPulse() => setState(() => _pulseKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Анимации')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CounterCard(key: ValueKey<int>(_pulseKey)),
          const SizedBox(height: 12),
          _ExpandingCard(expanded: _expanded, onToggle: _toggleExpanded),
          const SizedBox(height: 12),
          _StaggeredList(),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _restartPulse,
            child: const Text('Перезапустить анимации'),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _KitCard(
      title: 'Счётчик',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 128400),
        duration: MotionSpeed.slow.duration,
        curve: standardCurve,
        builder: _buildValue,
      ),
    );
  }

  Widget _buildValue(BuildContext context, double value, Widget? child) {
    return Text(
      '${formatCounter(value)} шагов',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _ExpandingCard extends StatelessWidget {
  const _ExpandingCard({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _KitCard(
      title: 'Разворот',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: MotionSpeed.normal.duration,
            curve: standardCurve,
            child: _ExpandedText(expanded: expanded),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(expanded ? 'Свернуть' : 'Развернуть'),
          ),
        ],
      ),
    );
  }
}

class _ExpandedText extends StatelessWidget {
  const _ExpandedText({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Text(
      expanded ? 'Полное описание наряда с адресом, клиентом и SLA.' : 'Кратко',
    );
  }
}

class _StaggeredList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = progressSteps(count: 3);

    return _KitCard(
      title: 'Каскад',
      child: Column(
        children: [
          for (final (index, step) in steps.indexed)
            _StaggeredRow(index: index, progress: step),
        ],
      ),
    );
  }
}

class _StaggeredRow extends StatelessWidget {
  const _StaggeredRow({required this.index, required this.progress});

  final int index;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: staggeredDelay(index: index, speed: MotionSpeed.normal),
      curve: standardCurve,
      builder: _buildRow,
    );
  }

  Widget _buildRow(BuildContext context, double value, Widget? child) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, slideOffset(value)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('Шаг ${index + 1} из ${progressSteps(count: 3).length}'),
        ),
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  const _KitCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
