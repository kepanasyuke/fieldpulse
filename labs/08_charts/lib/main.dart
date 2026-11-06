import 'package:flutter/material.dart';

import 'package:lab_charts/src/chart_math.dart';
import 'package:lab_charts/src/ui/bar_chart.dart';
import 'package:lab_charts/src/ui/kit.dart';

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
      theme: _theme(),
      home: const ChartsPage(),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00639B)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика нарядов')),
      body: _body(),
    );
  }

  Widget _body() {
    return ListView(padding: const EdgeInsets.all(16), children: _sections());
  }

  List<Widget> _sections() {
    return [
      _summaryCard(),
      const SizedBox(height: 12),
      _PeriodSwitcher(days: _days, onSelect: _selectDays),
      const SizedBox(height: 12),
      const BarChartCard(points: _week),
    ];
  }

  Widget _summaryCard() {
    final values = _week.map((point) => point.value).toList(growable: false);
    final average = movingAverage(values, 3).last;

    return TitledCard(
      title: 'Сводка',
      child: _SummaryLines(average: average, peak: maxValue(values)),
    );
  }
}

class _SummaryLines extends StatelessWidget {
  const _SummaryLines({required this.average, required this.peak});

  final double average;
  final double peak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _lines(),
    );
  }

  List<Widget> _lines() {
    return [
      ValueLine(label: 'Пик', value: formatCompact(peak)),
      ValueLine(label: 'Среднее за 3 дня', value: formatCompact(average)),
    ];
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.days, required this.onSelect});

  final int days;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: _segments(),
      selected: {days},
      onSelectionChanged: _onChanged,
    );
  }

  List<ButtonSegment<int>> _segments() {
    return const [
      ButtonSegment<int>(value: 1, label: Text('Сутки')),
      ButtonSegment<int>(value: 7, label: Text('Неделя')),
      ButtonSegment<int>(value: 30, label: Text('Месяц')),
    ];
  }

  void _onChanged(Set<int> selection) => onSelect(selection.first);
}
