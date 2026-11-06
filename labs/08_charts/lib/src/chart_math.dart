class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

double maxValue(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

double barFraction({
  required double value,
  required double max,
  double minFraction = 0.02,
}) {
  if (max <= 0 || value <= 0) {
    return 0;
  }
  final ratio = (value / max).clamp(0.0, 1.0);
  return ratio < minFraction ? minFraction : ratio;
}

List<double> normalize(List<double> values) {
  final top = maxValue(values);
  return values
      .map((value) => top <= 0 ? 0.0 : value / top)
      .toList(growable: false);
}

List<double> movingAverage(List<double> values, int window) {
  if (window <= 1 || values.isEmpty) {
    return List<double>.from(values, growable: false);
  }
  final size = window > values.length ? values.length : window;
  final result = <double>[];
  var sum = 0.0;
  for (var index = 0; index < values.length; index++) {
    sum += values[index];
    if (index >= size) {
      sum -= values[index - size];
    }
    final counted = index + 1 < size ? index + 1 : size;
    result.add(sum / counted);
  }
  return List<double>.unmodifiable(result);
}

double axisStep(double max) {
  if (max <= 0) {
    return 1;
  }
  final raw = max / 4;
  final magnitude = raw < 1 ? 1.0 : raw.roundToDouble();
  return magnitude;
}

List<double> axisTicks(double max, {int count = 4}) => List<double>.generate(
  count + 1,
  (index) => max / count * index,
  growable: false,
);

String formatCompact(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.round().toString();
}

String periodLabel(int days) => days == 1 ? 'за сутки' : 'за $days дней';

double conversionRate({required double actions, required double visits}) =>
    visits <= 0 ? 0 : (actions / visits * 100).clamp(0, 100);
