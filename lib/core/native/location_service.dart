import 'package:geolocator/geolocator.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/models/coordinates.dart';
import 'package:fieldpulse/core/utils/result.dart';

class LocationService {
  LocationService(this._geolocator);

  final GeolocatorPlatform _geolocator;

  Future<Result<Coordinates>> currentPosition() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Err(
        GeolocationFailure('Включите геолокацию в настройках устройства'),
      );
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const Err(
        PermissionFailure('Доступ к геолокации запрещён навсегда'),
      );
    }
    if (permission == LocationPermission.denied) {
      return const Err(PermissionFailure('Доступ к геолокации не выдан'));
    }

    try {
      final position = await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Ok(
        Coordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
      );
    } on Exception catch (error) {
      return Err(GeolocationFailure('Не удалось определить точку: $error'));
    }
  }

  double distanceBetween(Coordinates from, Coordinates to) =>
      _geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
}
