import 'package:flutter_test/flutter_test.dart';

import 'package:lab_geo_tracking/src/geo.dart';

void main() {
  const origin = GeoPoint(latitude: 55.7601, longitude: 37.6110);

  const near = RouteStop(
    id: 'r-1',
    title: 'Тверская',
    point: GeoPoint(latitude: 55.7649, longitude: 37.6055),
  );
  const far = RouteStop(
    id: 'r-4',
    title: 'Сокол',
    point: GeoPoint(latitude: 55.8055, longitude: 37.5150),
  );

  group('distanceInMeters', () {
    test('ноль для той же точки', () {
      expect(distanceInMeters(origin, origin), 0);
    });

    test('расстояние до Тверской в разумных пределах', () {
      final distance = distanceInMeters(origin, near.point);
      expect(distance, greaterThan(400));
      expect(distance, lessThan(900));
    });

    test('симметрично', () {
      expect(
        distanceInMeters(origin, far.point).round(),
        distanceInMeters(far.point, origin).round(),
      );
    });
  });

  group('сортировка и фильтрация', () {
    test('сортирует по удалённости от исходной точки', () {
      final ordered = sortByDistance([far, near], origin);
      expect(ordered.first.id, 'r-1');
      expect(ordered.last.id, 'r-4');
    });

    test('радиус отсекает далёкие точки', () {
      final inside = filterWithinRadius(
        [near, far],
        origin,
        radiusMeters: 1500,
      );
      expect(inside.map((stop) => stop.id), ['r-1']);
    });

    test('пустой список даёт нулевую длину маршрута', () {
      expect(totalRouteLength(const [], origin), 0);
    });

    test('длина маршрута считает путь от точки старта', () {
      final length = totalRouteLength([near, far], origin);
      expect(length, greaterThan(distanceInMeters(origin, far.point)));
    });
  });

  group('formatDistance', () {
    test('метры до километра', () {
      expect(formatDistance(320), '320 м');
    });

    test('километры с одним знаком до 10 км', () {
      expect(formatDistance(5400), '5.4 км');
    });

    test('целые километры на длинных дистанциях', () {
      expect(formatDistance(24800), '25 км');
    });
  });
}
