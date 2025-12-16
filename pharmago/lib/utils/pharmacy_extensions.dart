import 'package:pharmago/models/pharmacy.dart';

extension PharmacyDistanceExtension on Pharmacy {
  /// Distance formatée pour l'UI (ex: 350 m, 1.2 km)
  /// Utilise la méthode distanceFrom() déjà présente dans Pharmacy
  String formatDistanceFrom(double userLat, double userLng) {
    final distanceKm = distanceFrom(userLat, userLng);

    if (distanceKm < 1.0) {
      // Moins de 1 km : afficher en mètres
      final distanceM = (distanceKm * 1000).round();
      return '$distanceM m';
    } else {
      // 1 km ou plus : afficher en km avec 1 décimale
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
