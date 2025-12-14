/// Modèle de pharmacie pour l'application PharmaGo
/// Compatible avec les données du backend .NET + Supabase
class Pharmacy {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String commune;
  final String quartier;
  final String phone;
  final List<String> assurances;
  final OpeningHours? openHours;
  final bool isGuard;
  final DateTime updatedAt;

  Pharmacy({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.commune,
    required this.quartier,
    required this.phone,
    required this.assurances,
    this.openHours,
    required this.isGuard,
    required this.updatedAt,
  });

  /// Crée une pharmacie depuis JSON (backend)
  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      commune: json['commune'] as String? ?? '',
      quartier: json['quartier'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      assurances: (json['assurances'] as List?)?.cast<String>() ?? [],
      openHours: json['open_hours'] != null
          ? OpeningHours.fromJson(json['open_hours'])
          : null,
      isGuard: json['is_guard'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Calcule la distance depuis une position GPS
  double distanceFrom(double userLat, double userLng) {
    return _calculateDistance(userLat, userLng, lat, lng);
  }

  /// Vérifie si la pharmacie est ouverte actuellement
  bool get isOpenNow {
    if (openHours == null) return true; // Assume ouvert si pas d'horaires

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return currentTime.compareTo(openHours!.open) >= 0 &&
        currentTime.compareTo(openHours!.close) <= 0;
  }

  /// Obtient le statut (Ouvert/Fermé)
  String get status => isOpenNow ? 'Ouvert' : 'Fermé';

  /// Obtient l'heure de fermeture formatée
  String get closingTimeText {
    if (openHours == null) return '';
    return isOpenNow
        ? 'Ferme à ${openHours!.close}'
        : 'Ouvre à ${openHours!.open}';
  }

  /// Formule de Haversine simplifiée pour calculer la distance
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    const double pi = 3.14159265359;

    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        (1 - _fastCos(dLat)) / 2 +
        _fastCos(lat1 * pi / 180) *
            _fastCos(lat2 * pi / 180) *
            (1 - _fastCos(dLon)) /
            2;

    return earthRadius * 2 * _fastAsin(_fastSqrt(a));
  }

  // Approximations rapides pour sin/cos/sqrt/asin
  static double _fastCos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _fastSqrt(double x) {
    if (x <= 0) return 0;
    double z = x;
    for (int i = 0; i < 5; i++) {
      z = (z + x / z) / 2;
    }
    return z;
  }

  static double _fastAsin(double x) =>
      x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
}

/// Horaires d'ouverture d'une pharmacie
class OpeningHours {
  final String open;
  final String close;

  OpeningHours({required this.open, required this.close});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      open: json['open'] as String,
      close: json['close'] as String,
    );
  }
}
