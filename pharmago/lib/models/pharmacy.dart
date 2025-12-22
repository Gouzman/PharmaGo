/// Modèle de pharmacie pour l'application PharmaGo
/// Compatible avec les données du backend .NET + Supabase
import 'dart:math' as math;
import '../utils/pharmacy_formatter.dart';

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
  /// Applique la normalisation des données OSM
  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    // Récupérer les valeurs brutes
    final rawName = (json['name'] as String?) ?? '';
    final rawAddress = (json['address'] as String?) ?? '';
    final rawCommune = (json['commune'] as String?) ?? '';
    final rawQuartier = (json['quartier'] as String?) ?? '';
    final rawPhone = (json['phone'] as String?) ?? '';

    // Normaliser les valeurs
    String normalizedName = PharmacyFormatter.normalizeName(rawName);

    // Si le nom est mal formé, générer un nom de fallback
    if (PharmacyFormatter.isNameMalformed(rawName)) {
      normalizedName = PharmacyFormatter.generateFallbackName(
        rawCommune,
        rawQuartier,
      );
    }

    // Détecter automatiquement si c'est une pharmacie de garde
    // Priorité : valeur JSON > détection automatique
    bool isGuardPharmacy =
        json['is_guard'] as bool? ??
        PharmacyFormatter.detectIsGuard(
          name: rawName,
          osmTags: json['osm_tags'] as Map<String, dynamic>?,
        );

    return Pharmacy(
      id: json['id'] as String,
      name: normalizedName,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: PharmacyFormatter.normalizeAddress(rawAddress),
      commune: PharmacyFormatter.normalizeCommune(rawCommune),
      quartier: PharmacyFormatter.normalizeQuartier(rawQuartier),
      phone: PharmacyFormatter.formatPhoneNumber(rawPhone),
      assurances: (json['assurances'] as List?)?.cast<String>() ?? [],
      openHours: json['open_hours'] != null
          ? OpeningHours.fromJson(json['open_hours'])
          : null,
      isGuard: isGuardPharmacy,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Calcule la distance depuis une position GPS
  double distanceFrom(double userLat, double userLng) {
    // Formule de Haversine (distance entre 2 points GPS)
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat - userLat);
    final dLng = _degreesToRadians(lng - userLng);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(userLat)) *
            math.cos(_degreesToRadians(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c; // Distance en km
  }

  /// Formate la distance pour l'affichage (ex: 350 m, 1.2 km)
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

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Vérifie si la pharmacie est ouverte actuellement
  bool get isOpenNow {
    // Si pas d'horaires définies, considérer comme fermée (sauf si de garde)
    if (openHours == null) return isGuard;

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Vérifier si l'heure actuelle est dans les horaires d'ouverture
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
