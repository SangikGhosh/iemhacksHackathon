import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.failure, this.message);

  final LocationFailure failure;
  final String message;

  bool get canOpenSettings => failure == LocationFailure.deniedForever;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService._();

  static Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Location is switched off. Turn it on to find points near you.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.deniedForever,
        'Location access is blocked. Enable it in Settings to see nearby points.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationFailure.denied,
        'Location access is needed to find drop-off points near you.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);

      throw const LocationException(
        LocationFailure.unavailable,
        'Could not get your location. Please try again.',
      );
    }
  }

  static Future<void> openSettings() => Geolocator.openAppSettings();
}
