import 'package:flutter/material.dart';

import 'package:lab_motion_kit/src/motion.dart';
import 'package:lab_motion_kit/src/ui/kit_card.dart';

class CounterCard extends StatelessWidget {
  const CounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return KitCard(title: 'Счётчик', child: _counter());
  }

  Widget _counter() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 128400),
      duration: MotionSpeed.slow.duration,
      curve: standardCurve,
      builder: _valueBuilder,
    );
  }

  Widget _valueBuilder(BuildContext context, double value, Widget? child) {
    return CaptionText(
      text: '${formatCounter(value)} шагов',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class ExpandingCard extends StatelessWidget {
  const ExpandingCard({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return KitCard(title: 'Разворот', child: _content());
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parts(),
    );
  }

  List<Widget> _parts() {
    return [
      AnimatedSize(
        duration: MotionSpeed.normal.duration,
        curve: standardCurve,
        child: _ExpandedText(expanded: expanded),
      ),
      TextButton(
        onPressed: onToggle,
        child: Text(expanded ? 'Свернуть' : 'Развернуть'),
      ),
    ];
  }
}

class _ExpandedText extends StatelessWidget {
  const _ExpandedText({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return CaptionText(text: _text());
  }

  String _text() {
    return expanded
        ? 'Полное описание наряда с адресом, клиентом и SLA.'
        : 'Кратко';
  }
}

class StaggeredList extends StatelessWidget {
  const StaggeredList({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return KitCard(title: 'Каскад', child: _rows());
  }

  Widget _rows() {
    return Column(children: _items());
  }

  List<Widget> _items() {
    return [
      for (final index in List<int>.generate(count, (value) => value))
        StaggeredRow(index: index, count: count),
    ];
  }
}

class StaggeredRow extends StatelessWidget {
  const StaggeredRow({super.key, required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: staggeredDelay(index: index, speed: MotionSpeed.normal),
      curve: standardCurve,
      builder: _rowBuilder,
    );
  }

  Widget _rowBuilder(BuildContext context, double value, Widget? child) {
    return Opacity(opacity: value, child: _shifted(value));
  }

  Widget _shifted(double value) {
    return Transform.translate(
      offset: Offset(0, slideOffset(value)),
      child: _label(),
    );
  }

  Widget _label() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CaptionText(text: 'Шаг ${index + 1} из $count'),
    );
  }
}
