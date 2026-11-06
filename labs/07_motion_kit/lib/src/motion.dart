import 'package:flutter/animation.dart';

enum MotionSpeed {
  fast(Duration(milliseconds: 150)),
  normal(Duration(milliseconds: 280)),
  slow(Duration(milliseconds: 450));

  const MotionSpeed(this.duration);

  final Duration duration;
}

const Curve standardCurve = Curves.easeOutCubic;
const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

double slideOffset(double progress) => (1 - progress) * 24;

double pulseScale(double progress) => 1 + 0.04 * (1 - progress);

double counterValue({
  required double progress,
  required double target,
  double start = 0,
}) => start + (target - start) * progress;

Duration staggeredDelay({
  required int index,
  MotionSpeed speed = MotionSpeed.fast,
}) => speed.duration * index;

String formatCounter(double value) => value.round().toString();

List<double> progressSteps({required int count}) => List<double>.generate(
  count,
  (index) => count == 0 ? 0 : (index + 1) / count,
  growable: false,
);
