import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service Flutter pour charger et gérer les pharmacies depuis le backend
class PharmacyDataService {
  // 🔧 Configurez votre URL backend ici (ou null pour utiliser les données de test)
  static const String? _backendUrl =
      null; // Changez en 'http://localhost:5000' pour backend local
  static const String _cacheKey = 'pharmacies_cache';
  static const String _versionKey = 'pharmacies_version';

  // Mode de test : utilise des données locales si le backend n'est pas configuré
  static const bool _useTestData = true;

  /// Charge les pharmacies depuis le cache ou le backend
  Future<PharmacyData?> loadPharmacies({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // MODE TEST : Utiliser des données de démonstration
    if (_useTestData && _backendUrl == null) {
      print('🧪 Mode TEST : Utilisation de données de démonstration');
      return _getTestData();
    }

    // 1. Essayer de charger depuis le cache si pas de refresh forcé
    if (!forceRefresh) {
      final cachedJson = prefs.getString(_cacheKey);
      final cachedVersion = prefs.getInt(_versionKey);

      if (cachedJson != null && cachedVersion != null) {
        print('📦 Chargement depuis le cache local');
        return PharmacyData.fromJson(jsonDecode(cachedJson));
      }
    }

    // 2. Récupérer l'URL du JSON depuis le backend
    try {
      print('🌐 Récupération de l\'URL du JSON...');
      final latestResponse = await http
          .get(Uri.parse('$_backendUrl/api/pharmacies/latest'))
          .timeout(const Duration(seconds: 10));

      if (latestResponse.statusCode != 200) {
        throw Exception('Impossible de récupérer l\'URL du JSON');
      }

      final latestData = jsonDecode(latestResponse.body);
      final jsonUrl = latestData['url'] as String;

      // 3. Télécharger le JSON depuis Supabase Storage
      print('📥 Téléchargement du JSON depuis: $jsonUrl');
      final pharmaciesResponse = await http.get(Uri.parse(jsonUrl));

      if (pharmaciesResponse.statusCode != 200) {
        throw Exception('Impossible de télécharger le JSON');
      }

      final pharmaciesJson = jsonDecode(pharmaciesResponse.body);
      final data = PharmacyData.fromJson(pharmaciesJson);

      // 4. Vérifier si la version a changé
      final cachedVersion = prefs.getInt(_versionKey);
      if (cachedVersion != data.version) {
        print('✨ Nouvelle version détectée: ${data.version}');

        // 5. Sauvegarder en cache
        await prefs.setString(_cacheKey, pharmaciesResponse.body);
        await prefs.setInt(_versionKey, data.version);

        print('✅ Cache mis à jour avec ${data.pharmacies.length} pharmacies');
      } else {
        print('ℹ️ Version inchangée');
      }

      return data;
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');

      // Fallback: essayer de charger depuis le cache même si expiré
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        print('⚠️ Utilisation du cache expiré comme fallback');
        return PharmacyData.fromJson(jsonDecode(cachedJson));
      }

      // Dernier fallback : données de test si disponible
      if (_useTestData) {
        print('🧪 Fallback vers les données de test');
        return _getTestData();
      }

      return null;
    }
  }

  /// Données de test pour démonstration (Abidjan, Côte d'Ivoire)
  PharmacyData _getTestData() {
    final now = DateTime.now();
    final testJson = {
      "version": now.millisecondsSinceEpoch,
      "generated_at": now.toIso8601String(),
      "pharmacies": [
        {
          "id": "test-001",
          "name": "Pharmacie St Gabriel",
          "lat": 5.345317,
          "lng": -4.024429,
          "address": "Bd des Martyrs, Marcory",
          "commune": "Marcory",
          "quartier": "Zone 4",
          "phone": "07 09 02 73 56",
          "assurances": ["MUGEFCI", "INPS", "AXA"],
          "open_hours": {"open": "08:00", "close": "20:00"},
          "is_guard": true,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-002",
          "name": "Pharmacie de la Riviera",
          "lat": 5.355317,
          "lng": -4.014429,
          "address": "Avenue 18, Riviera Palmeraie",
          "commune": "Cocody",
          "quartier": "Riviera Palmeraie",
          "phone": "27 21 23 45 67",
          "assurances": ["MUGEFCI", "CNPS"],
          "open_hours": {"open": "07:00", "close": "22:00"},
          "is_guard": false,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-003",
          "name": "Pharmacie Principale d'Abobo",
          "lat": 5.416891,
          "lng": -4.018132,
          "address": "Autoroute d'Abobo, Aboboté",
          "commune": "Abobo",
          "quartier": "Aboboté",
          "phone": "42 52 77 79",
          "assurances": ["MUGEFCI", "INPS", "AXA", "SAHAM"],
          "open_hours": {"open": "08:00", "close": "20:00"},
          "is_guard": false,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-004",
          "name": "Pharmacie du Plateau",
          "lat": 5.324912,
          "lng": -4.023582,
          "address": "Rue du Commerce, Plateau",
          "commune": "Plateau",
          "quartier": "Centre des Affaires",
          "phone": "27 20 21 22 23",
          "assurances": ["MUGEFCI", "CNPS", "AXA"],
          "open_hours": {"open": "08:00", "close": "21:00"},
          "is_guard": true,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-005",
          "name": "Pharmacie Yopougon",
          "lat": 5.335789,
          "lng": -4.087654,
          "address": "Rue Princesse, Yopougon Sideci",
          "commune": "Yopougon",
          "quartier": "Sideci",
          "phone": "05 06 07 08 09",
          "assurances": ["MUGEFCI", "INPS"],
          "open_hours": {"open": "08:00", "close": "19:00"},
          "is_guard": false,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-006",
          "name": "Pharmacie Treichville",
          "lat": 5.302156,
          "lng": -4.012389,
          "address": "Avenue 7, Treichville",
          "commune": "Treichville",
          "quartier": "Zone 3",
          "phone": "27 21 34 56 78",
          "assurances": ["MUGEFCI", "CNPS", "AXA", "SAHAM"],
          "open_hours": {"open": "07:30", "close": "21:30"},
          "is_guard": false,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-007",
          "name": "Pharmacie Adjamé",
          "lat": 5.361234,
          "lng": -4.030567,
          "address": "Boulevard Nangui Abrogoua, Adjamé",
          "commune": "Adjamé",
          "quartier": "Liberté",
          "phone": "27 20 32 45 67",
          "assurances": ["MUGEFCI", "INPS", "AXA"],
          "open_hours": {"open": "08:00", "close": "20:00"},
          "is_guard": false,
          "updated_at": now.toIso8601String(),
        },
        {
          "id": "test-008",
          "name": "Pharmacie Cocody Angré",
          "lat": 5.383456,
          "lng": -3.987234,
          "address": "Rue des Jardins, Cocody Angré",
          "commune": "Cocody",
          "quartier": "Angré 8ème Tranche",
          "phone": "27 22 45 67 89",
          "assurances": ["MUGEFCI", "CNPS", "AXA", "SAHAM", "ALLIANZ"],
          "open_hours": {"open": "07:00", "close": "22:00"},
          "is_guard": true,
          "updated_at": now.toIso8601String(),
        },
      ],
    };

    return PharmacyData.fromJson(testJson);
  }

  /// Vérifie s'il y a une mise à jour disponible
  Future<bool> hasUpdate() async {
    // Mode test : toujours retourner false
    if (_useTestData && _backendUrl == null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt(_versionKey);

      if (cachedVersion == null) return true;

      final latestResponse = await http
          .get(Uri.parse('$_backendUrl/api/pharmacies/latest'))
          .timeout(const Duration(seconds: 5));

      if (latestResponse.statusCode != 200) return false;

      final latestData = jsonDecode(latestResponse.body);
      final jsonUrl = latestData['url'] as String;

      final pharmaciesResponse = await http.get(Uri.parse(jsonUrl));
      if (pharmaciesResponse.statusCode != 200) return false;

      final pharmaciesJson = jsonDecode(pharmaciesResponse.body);
      final remoteVersion = pharmaciesJson['version'] as int;

      return remoteVersion > cachedVersion;
    } catch (e) {
      print('❌ Erreur lors de la vérification de mise à jour: $e');
      return false;
    }
  }

  /// Efface le cache local
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_versionKey);
    print('🗑️ Cache effacé');
  }
}

/// Modèle de données pour le JSON versionné
class PharmacyData {
  final int version;
  final DateTime generatedAt;
  final List<Pharmacy> pharmacies;

  PharmacyData({
    required this.version,
    required this.generatedAt,
    required this.pharmacies,
  });

  factory PharmacyData.fromJson(Map<String, dynamic> json) {
    return PharmacyData(
      version: json['version'] as int,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      pharmacies: (json['pharmacies'] as List)
          .map((p) => Pharmacy.fromJson(p))
          .toList(),
    );
  }
}

/// Modèle de pharmacie
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

  /// Calcule la distance depuis une position GPS (formule de Haversine)
  double distanceFrom(double userLat, double userLng) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    const double pi = 3.14159265359;

    final dLat = (lat - userLat) * pi / 180;
    final dLon = (lng - userLng) * pi / 180;

    final a =
        (1 - _fastCos(dLat)) / 2 +
        _fastCos(userLat * pi / 180) *
            _fastCos(lat * pi / 180) *
            (1 - _fastCos(dLon)) /
            2;

    return earthRadius * 2 * _fastAsin(_fastSqrt(a));
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

  // Approximations rapides pour les calculs trigonométriques
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

/// Modèle des horaires d'ouverture
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

/// Exemple d'utilisation dans votre app Flutter
/// 
/// ```dart
/// final service = PharmacyDataService();
/// 
/// // Charger les pharmacies
/// final data = await service.loadPharmacies();
/// if (data != null) {
///   print('${data.pharmacies.length} pharmacies chargées');
///   
///   // Filtrer les pharmacies de garde
///   final guardes = data.pharmacies.where((p) => p.isGuard).toList();
///   
///   // Afficher sur la carte OpenStreetMap
///   for (var pharmacy in data.pharmacies) {
///     addMarker(LatLng(pharmacy.lat, pharmacy.lng), pharmacy.name);
///   }
/// }
/// 
/// // Vérifier les mises à jour
/// if (await service.hasUpdate()) {
///   final updated = await service.loadPharmacies(forceRefresh: true);
/// }
/// ```
