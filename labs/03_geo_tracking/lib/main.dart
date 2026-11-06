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
    setState(() {
      _locating = true;
      _status = 'Запрашиваю геопозицию…';
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _status = 'Доступ к геопозиции не выдан';
            _locating = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _origin = GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _status = 'Моя точка: $_origin (±${position.accuracy.round()} м)';
        _locating = false;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Геолокация недоступна: $error';
        _locating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = sortByDistance(_stops, _origin);
    final total = totalRouteLength(_stops, _origin);

    return Scaffold(
      appBar: AppBar(title: const Text('Маршрут дня')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Длина маршрута: ${formatDistance(total)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _locating ? null : _locate,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(
                      _locating ? 'Определяю…' : 'Определить мою точку',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final stop in ordered)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text('${ordered.indexOf(stop) + 1}'),
                ),
                title: Text(stop.title),
                subtitle: Text(stop.point.toString()),
                trailing: Text(
                  formatDistance(stop.distanceFrom(_origin)),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
