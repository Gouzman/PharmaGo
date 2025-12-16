import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// LocationService
/// - centralise la logique de permission + récupération position
/// - expose des méthodes async simples : requestPermission(), getCurrentPosition(), getPositionStream()
class LocationService {
  /// Request required permissions (WhenInUse). Returns true if granted.
  Future<bool> requestPermission() async {
    // Vérifier la permission actuelle avec Geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    // Demander la permission si refusée
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }
    }

    return false;
  }

  /// Get current position once (with a timeout).
  Future<Position> getCurrentPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Check service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException('Location services are disabled.');
    }

    // Check / request permission using Geolocator native API
    final granted = await requestPermission();
    if (!granted) {
      throw PermissionDeniedException('Location permission denied.');
    }

    // Try retrieving high accuracy position with timeout
    try {
      final settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: timeout,
      );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      return pos;
    } on TimeoutException {
      // fallback to last known position
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  /// Stream of positions (useful to follow user when navigating).
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10,
  }) {
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Convenience: convert Position -> LatLng-like
  static LatLng toLatLng(Position p) =>
      LatLng(latitude: p.latitude, longitude: p.longitude);
}

/// Simple custom exceptions to surface errors meaningfully
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);
  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

/// Small LatLng class used here to avoid importing map packages in util
class LatLng {
  final double latitude;
  final double longitude;
  LatLng({required this.latitude, required this.longitude});
}
