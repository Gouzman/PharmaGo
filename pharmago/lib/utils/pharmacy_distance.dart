/// Utilitaire statique pour le calcul de distance entre l'utilisateur et une pharmacie
/// Solution pour contourner le bug de cache Kernel Dart iOS
///
/// Utilise la formule de Haversine pour calculer la distance orthodromique
/// entre deux points GPS (grande cercle sur une sphère)
import 'dart:math';

class PharmacyDistance {
  // Rayon de la Terre en mètres
  static const double _earthRadiusMeters = 6371000.0;

  /// Calcule la distance en mètres entre deux coordonnées GPS
  ///
  /// Paramètres :
  /// - [userLat] : latitude de l'utilisateur (degrés décimaux)
  /// - [userLng] : longitude de l'utilisateur (degrés décimaux)
  /// - [pharmacyLat] : latitude de la pharmacie (degrés décimaux)
  /// - [pharmacyLng] : longitude de la pharmacie (degrés décimaux)
  ///
  /// Retourne la distance en mètres
  static double distanceInMeters({
    required double userLat,
    required double userLng,
    required double pharmacyLat,
    required double pharmacyLng,
  }) {
    // Conversion degrés → radians
    final dLat = _degToRad(pharmacyLat - userLat);
    final dLng = _degToRad(pharmacyLng - userLng);

    // Formule de Haversine
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(userLat)) *
            cos(_degToRad(pharmacyLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Formate la distance pour l'affichage UI
  ///
  /// Retourne :
  /// - "X m" si distance < 1000 m (ex: "350 m")
  /// - "X.X km" si distance >= 1000 m (ex: "1.2 km")
  ///
  /// Paramètres :
  /// - [userLat] : latitude de l'utilisateur
  /// - [userLng] : longitude de l'utilisateur
  /// - [pharmacyLat] : latitude de la pharmacie
  /// - [pharmacyLng] : longitude de la pharmacie
  static String formatDistance({
    required double userLat,
    required double userLng,
    required double pharmacyLat,
    required double pharmacyLng,
  }) {
    final distanceM = distanceInMeters(
      userLat: userLat,
      userLng: userLng,
      pharmacyLat: pharmacyLat,
      pharmacyLng: pharmacyLng,
    );

    if (distanceM < 1000) {
      return '${distanceM.toStringAsFixed(0)} m';
    } else {
      final distanceKm = distanceM / 1000;
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Conversion degrés → radians
  static double _degToRad(double deg) => deg * pi / 180.0;
}
