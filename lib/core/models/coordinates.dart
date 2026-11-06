import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class Coordinates extends Equatable {
  const Coordinates({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  double distanceTo(Coordinates other) {
    const earthRadius = 6371000.0;
    final dLat = _radians(other.latitude - latitude);
    final dLng = _radians(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  @override
  List<Object?> get props => [latitude, longitude, accuracyMeters];
}
