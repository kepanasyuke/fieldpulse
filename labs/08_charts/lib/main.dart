import 'package:flutter/material.dart';

import 'package:lab_charts/src/chart_math.dart';

const List<ChartPoint> _week = [
  ChartPoint(label: 'пн', value: 420),
  ChartPoint(label: 'вт', value: 610),
  ChartPoint(label: 'ср', value: 380),
  ChartPoint(label: 'чт', value: 900),
  ChartPoint(label: 'пт', value: 1240),
  ChartPoint(label: 'сб', value: 300),
  ChartPoint(label: 'вс', value: 210),
];

void main() => runApp(const ChartsApp());

class ChartsApp extends StatelessWidget {
  const ChartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 08 · Charts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00639B)),
      ),
      home: const ChartsPage(),
    );
  }
}

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _days = 7;

  void _selectDays(int days) => setState(() => _days = days);

  @override
  Widget build(BuildContext context) {
    final values = _week.map((point) => point.value).toList(growable: false);
    final average = movingAverage(values, 3).last;

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика нарядов')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(average: average, total: maxValue(values)),
          const SizedBox(height: 12),
          _PeriodSwitcher(days: _days, onSelect: _selectDays),
          const SizedBox(height: 12),
          _BarChartCard(points: _week),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.average, required this.total});

  final double average;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Пик: ${formatCompact(total)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Среднее за 3 дня: ${formatCompact(average)}'),
          ],
        ),
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.days, required this.onSelect});

  final int days;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(value: 1, label: Text('Сутки')),
        ButtonSegment<int>(value: 7, label: Text('Неделя')),
        ButtonSegment<int>(value: 30, label: Text('Месяц')),
      ],
      selected: {days},
      onSelectionChanged: (selection) => onSelect(selection.first),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final top = maxValue(
      points.map((point) => point.value).toList(growable: false),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points) _Bar(point: point, max: top),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.point, required this.max});

  final ChartPoint point;
  final double max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            formatCompact(point.value),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: barFraction(value: point.value, max: max) * 160,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(point.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
