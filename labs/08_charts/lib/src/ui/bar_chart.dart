import 'package:flutter/material.dart';

import 'package:lab_charts/src/chart_math.dart';
import 'package:lab_charts/src/ui/kit.dart';

class BarChartCard extends StatelessWidget {
  const BarChartCard({super.key, required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return TitledCard(
      title: 'Наряды по дням',
      child: _BarRow(points: points),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _bars()),
    );
  }

  List<Widget> _bars() {
    final top = maxValue(
      points.map((point) => point.value).toList(growable: false),
    );

    return [for (final point in points) BarColumn(point: point, max: top)];
  }
}

class BarColumn extends StatelessWidget {
  const BarColumn({super.key, required this.point, required this.max});

  final ChartPoint point;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _BarStack(point: point, max: max),
    );
  }
}

class _BarStack extends StatelessWidget {
  const _BarStack({required this.point, required this.max});

  final ChartPoint point;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: _parts(context),
    );
  }

  List<Widget> _parts(BuildContext context) {
    return [
      _BarLabel(text: formatCompact(point.value)),
      const SizedBox(height: 4),
      _BarFill(
        fraction: barFraction(value: point.value, max: max),
      ),
      const SizedBox(height: 6),
      _BarLabel(text: point.label),
    ];
  }
}

class _BarFill extends StatelessWidget {
  const _BarFill({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: fraction * 160,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _decoration(context),
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(6),
    );
  }
}

class _BarLabel extends StatelessWidget {
  const _BarLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}
