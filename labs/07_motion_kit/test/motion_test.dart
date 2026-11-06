import 'package:flutter_test/flutter_test.dart';

import 'package:lab_motion_kit/src/motion.dart';

void main() {
  group('MotionSpeed', () {
    test('длительности растут от fast к slow', () {
      final fast = MotionSpeed.fast.duration.inMilliseconds;
      final normal = MotionSpeed.normal.duration.inMilliseconds;
      final slow = MotionSpeed.slow.duration.inMilliseconds;

      expect(fast, lessThan(normal));
      expect(normal, lessThan(slow));
    });

    test('каскадная задержка пропорциональна индексу', () {
      expect(staggeredDelay(index: 0).inMilliseconds, 0);
      expect(staggeredDelay(index: 2).inMilliseconds, 300);
    });
  });

  group('чистые хелперы анимации', () {
    test('slideOffset в начале больше, в конце ноль', () {
      expect(slideOffset(0), 24);
      expect(slideOffset(1), 0);
    });

    test('pulseScale слегка увеличивает в начале', () {
      expect(pulseScale(0), greaterThan(1));
      expect(pulseScale(1), 1);
    });

    test('counterValue интерполирует от старта к цели', () {
      expect(counterValue(progress: 0, target: 100), 0);
      expect(counterValue(progress: 0.5, target: 100), 50);
      expect(counterValue(progress: 1, target: 100, start: 20), 100);
    });

    test('formatCounter округляет до целого', () {
      expect(formatCounter(128399.7), '128400');
    });

    test('progressSteps даёт равномерные доли', () {
      expect(progressSteps(count: 4), [0.25, 0.5, 0.75, 1.0]);
      expect(progressSteps(count: 0), isEmpty);
    });
  });
}
