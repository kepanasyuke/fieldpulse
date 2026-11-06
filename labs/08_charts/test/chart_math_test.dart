import 'package:flutter_test/flutter_test.dart';

import 'package:lab_charts/src/chart_math.dart';

void main() {
  group('шкала графика', () {
    test('максимум и пустой список', () {
      expect(maxValue([3, 9, 4]), 9);
      expect(maxValue(const []), 0);
    });

    test('доля столбика ограничена 0..1', () {
      expect(barFraction(value: 50, max: 100), 0.5);
      expect(barFraction(value: 150, max: 100), 1);
      expect(barFraction(value: 0, max: 100), 0);
      expect(barFraction(value: 10, max: 0), 0);
    });

    test('минимальная доля не даёт исчезнуть столбику', () {
      expect(barFraction(value: 1, max: 1000), 0.02);
    });

    test('нормализация даёт единицу на максимуме', () {
      expect(normalize([10, 20, 40]), [0.25, 0.5, 1.0]);
      expect(normalize(const [0, 0]), [0.0, 0.0]);
    });
  });

  group('агрегация', () {
    test('скользящее среднее по окну 3', () {
      final result = movingAverage([3, 6, 9, 12], 3);

      expect(result.first, 3);
      expect(result[2], 6);
      expect(result.last, 9);
    });

    test('окно больше ряда считается по имеющимся точкам', () {
      expect(movingAverage([4, 8], 5), [4, 6]);
    });

    test('окно 1 не меняет значения', () {
      expect(movingAverage([5, 7], 1), [5, 7]);
    });

    test('доля конверсии не превышает 100%', () {
      expect(conversionRate(actions: 25, visits: 100), 25);
      expect(conversionRate(actions: 250, visits: 100), 100);
      expect(conversionRate(actions: 5, visits: 0), 0);
    });
  });

  group('подписи', () {
    test('компактные числа', () {
      expect(formatCompact(750), '750');
      expect(formatCompact(12400), '12.4k');
      expect(formatCompact(2500000), '2.5M');
    });

    test('шаг оси и засечки', () {
      expect(axisStep(1240), 310);
      expect(axisTicks(100).length, 5);
      expect(axisStep(0), 1);
    });

    test('подпись периода', () {
      expect(periodLabel(1), 'за сутки');
      expect(periodLabel(7), 'за 7 дней');
    });
  });
}
