import 'dart:math' as math;

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class RouteStop {
  const RouteStop({required this.id, required this.title, required this.point});

  final String id;
  final String title;
  final GeoPoint point;

  double distanceFrom(GeoPoint origin) => distanceInMeters(origin, point);

  RouteStop copyWith({GeoPoint? point}) =>
      RouteStop(id: id, title: title, point: point ?? this.point);
}

const double earthRadiusMeters = 6371000;

double distanceInMeters(GeoPoint from, GeoPoint to) {
  final dLat = _radians(to.latitude - from.latitude);
  final dLng = _radians(to.longitude - from.longitude);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(from.latitude)) *
          math.cos(_radians(to.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;

List<RouteStop> sortByDistance(List<RouteStop> stops, GeoPoint origin) {
  final sorted = [...stops];
  sorted.sort(
    (a, b) => a.distanceFrom(origin).compareTo(b.distanceFrom(origin)),
  );
  return sorted;
}

String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} м';
  }
  final kilometers = meters / 1000;
  return kilometers < 10
      ? '${kilometers.toStringAsFixed(1)} км'
      : '${kilometers.round()} км';
}

List<RouteStop> filterWithinRadius(
  List<RouteStop> stops,
  GeoPoint origin, {
  required double radiusMeters,
}) => stops
    .where((stop) => stop.distanceFrom(origin) <= radiusMeters)
    .toList(growable: false);

double totalRouteLength(List<RouteStop> stops, GeoPoint origin) {
  if (stops.isEmpty) {
    return 0;
  }
  final ordered = sortByDistance(stops, origin);
  var total = distanceInMeters(origin, ordered.first.point);
  for (var index = 1; index < ordered.length; index++) {
    total += distanceInMeters(ordered[index - 1].point, ordered[index].point);
  }
  return total;
}
