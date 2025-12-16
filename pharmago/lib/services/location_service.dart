import 'package:geolocator/geolocator.dart';

/// Service pour gérer la localisation GPS de l'utilisateur
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  bool _isPermissionGranted = false;

  /// Vérifie et demande les permissions de localisation
  Future<bool> requestPermission() async {
    try {
      // Vérifier le statut actuel avec l'API native Geolocator
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        _isPermissionGranted = true;
        return true;
      }

      if (permission == LocationPermission.denied) {
        // Demander la permission
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          _isPermissionGranted = true;
          return true;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission refusée définitivement
        _isPermissionGranted = false;
        return false;
      }

      _isPermissionGranted = false;
      return false;
    } catch (e) {
      // Erreur permission GPS
      _isPermissionGranted = false;
      return false;
    }
  }

  /// Vérifie si le service de localisation est activé
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position?> getCurrentPosition() async {
    try {
      // 1️⃣ Vérifier si le service de localisation est activé
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Services de localisation désactivés');
      }

      // 2️⃣ Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée');
      }

      // 3️⃣ Obtenir la position avec haute précision
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _lastPosition = position;
      _isPermissionGranted = true;
      return position;
    } catch (e) {
      // En cas d'erreur, retourner la dernière position connue
      return _lastPosition;
    }
  }

  /// Calcule la distance entre deux points (en mètres)
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Formatte une distance en km ou m
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Surveille les changements de position en temps réel
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Ouvre les paramètres de localisation
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Ouvre les paramètres de l'application pour modifier les permissions
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Getter pour la dernière position connue
  Position? get lastKnownPosition => _lastPosition;

  /// Getter pour l'état des permissions
  bool get hasPermission => _isPermissionGranted;
}
