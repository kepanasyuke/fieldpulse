import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lab_geo_tracking/src/geo.dart';

const GeoPoint _moscowOffice = GeoPoint(latitude: 55.7601, longitude: 37.6110);

final List<RouteStop> _stops = [
  const RouteStop(
    id: 'r-1',
    title: 'Тверская, 7',
    point: GeoPoint(latitude: 55.7649, longitude: 37.6055),
  ),
  const RouteStop(
    id: 'r-2',
    title: 'Арбат, 24',
    point: GeoPoint(latitude: 55.7496, longitude: 37.5920),
  ),
  const RouteStop(
    id: 'r-3',
    title: 'Парк Горького',
    point: GeoPoint(latitude: 55.7298, longitude: 37.6019),
  ),
  const RouteStop(
    id: 'r-4',
    title: 'Сокол',
    point: GeoPoint(latitude: 55.8055, longitude: 37.5150),
  ),
];

void main() => runApp(const GeoTrackingApp());

class GeoTrackingApp extends StatelessWidget {
  const GeoTrackingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lab 03 · Geo tracking',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6FEB)),
    ),
    home: const GeoPage(),
  );
}

class GeoPage extends StatefulWidget {
  const GeoPage({super.key});

  @override
  State<GeoPage> createState() => _GeoPageState();
}

class _GeoPageState extends State<GeoPage> {
  GeoPoint _origin = _moscowOffice;
  String _status = 'Координаты офиса (демо)';
  bool _locating = false;

  Future<void> _locate() async {
    _update(locating: true, status: 'Запрашиваю геопозицию…');
    final granted = await _ensurePermission();
    if (granted) {
      await _readPosition();
    } else {
      _update(locating: false, status: 'Доступ к геопозиции не выдан');
    }
  }

  Future<bool> _ensurePermission() async {
    final current = await Geolocator.checkPermission();
    final resolved = current == LocationPermission.denied
        ? await Geolocator.requestPermission()
        : current;

    return resolved == LocationPermission.whileInUse ||
        resolved == LocationPermission.always;
  }

  Future<void> _readPosition() async {
    try {
      _applyPosition(await _position());
    } on Exception catch (error) {
      _update(locating: false, status: 'Геолокация недоступна: $error');
    }
  }

  Future<Position> _position() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );

  void _applyPosition(Position position) {
    if (mounted) {
      setState(() {
        _origin = GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _status = 'Моя точка: $_origin (±${position.accuracy.round()} м)';
        _locating = false;
      });
    }
  }

  void _update({required bool locating, required String status}) {
    if (mounted) {
      setState(() {
        _locating = locating;
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordered = sortByDistance(_stops, _origin);

    return Scaffold(
      appBar: AppBar(title: const Text('Маршрут дня')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RouteSummary(
            status: _status,
            total: formatDistance(totalRouteLength(_stops, _origin)),
            isLocating: _locating,
            onLocate: _locate,
          ),
          const SizedBox(height: 12),
          for (final (index, stop) in ordered.indexed)
            _StopTile(
              number: index + 1,
              stop: stop,
              distance: formatDistance(stop.distanceFrom(_origin)),
            ),
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.status,
    required this.total,
    required this.isLocating,
    required this.onLocate,
  });

  final String status;
  final String total;
  final bool isLocating;
  final Future<void> Function() onLocate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Длина маршрута: $total', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLocating ? null : onLocate,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(isLocating ? 'Определяю…' : 'Определить мою точку'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.number,
    required this.stop,
    required this.distance,
  });

  final int number;
  final RouteStop stop;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('$number'),
        ),
        title: Text(stop.title),
        subtitle: Text(stop.point.toString()),
        trailing: Text(distance, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
