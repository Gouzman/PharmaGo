import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pharmacy.dart';

/// Service Flutter pour charger et gérer les pharmacies depuis le backend
class PharmacyDataService {
  // 🔧 URL PUBLIQUE DU JSON SUPABASE (accès direct sans backend)
  static const String _directJsonUrl =
      'https://wglrryhnrqninxzrmowh.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json';

  // 🔧 URL backend (optionnel, utilisé uniquement si _useDirectUrl = false)
  static const String? _backendUrl = null; // 'http://localhost:5000'

  static const String _cacheKey = 'pharmacies_cache';
  static const String _versionKey = 'pharmacies_version';

  // Mode direct : charge directement depuis Supabase (recommandé)
  static const bool _useDirectUrl = true;

  // Mode de test : utilise des données locales si activé
  static const bool _useTestData = false;

  // Cache activé (false = utilise le cache, true = ignore le cache)
  static const bool _ignoreCache = false;

  /// Charge les pharmacies depuis le cache ou le backend
  Future<PharmacyData?> loadPharmacies({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // MODE TEST : Utiliser des données de démonstration
    if (_useTestData) {
      return _getTestData();
    }

    // 1. Essayer de charger depuis le cache si pas de refresh forcé
    if (!forceRefresh && !_ignoreCache) {
      final cachedJson = prefs.getString(_cacheKey);
      final cachedVersion = prefs.getInt(_versionKey);

      if (cachedJson != null && cachedVersion != null) {
        return PharmacyData.fromJson(jsonDecode(cachedJson));
      }
    }

    // 2. Déterminer l'URL du JSON
    try {
      String jsonUrl;

      if (_useDirectUrl) {
        // MODE DIRECT : Utiliser l'URL publique Supabase
        jsonUrl = _directJsonUrl;
      } else {
        // MODE BACKEND : Récupérer l'URL depuis le backend .NET
        if (_backendUrl == null) {
          throw Exception('Backend URL not configured');
        }

        final latestResponse = await http
            .get(Uri.parse('$_backendUrl/api/pharmacies/latest'))
            .timeout(const Duration(seconds: 10));

        if (latestResponse.statusCode != 200) {
          throw Exception('Impossible de récupérer l\'URL du JSON');
        }

        final latestData = jsonDecode(latestResponse.body);
        jsonUrl = latestData['url'] as String;
      }

      // 3. Télécharger le JSON depuis Supabase Storage
      final pharmaciesResponse = await http.get(Uri.parse(jsonUrl));

      if (pharmaciesResponse.statusCode != 200) {
        throw Exception('Impossible de télécharger le JSON');
      }

      final pharmaciesJson = jsonDecode(pharmaciesResponse.body);
      final data = PharmacyData.fromJson(pharmaciesJson);

      // 4. Vérifier si la version a changé et sauvegarder en cache
      final cachedVersion = prefs.getInt(_versionKey);
      if (cachedVersion != data.version) {
        await prefs.setString(_cacheKey, pharmaciesResponse.body);
        await prefs.setInt(_versionKey, data.version);
      }

      return data;
    } catch (e, stack) {
      print('❌ Erreur lors du chargement: $e');
      print('Stack: $stack');

      // Fallback: essayer de charger depuis le cache même si expiré
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        return PharmacyData.fromJson(jsonDecode(cachedJson));
      }

      // Dernier fallback : données de test si disponible
      if (_useTestData) {
        print('⚠️ Fallback vers les données de test');
        return _getTestData();
      }

      print('💥 Aucune donnée disponible');
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
    if (_useTestData) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt(_versionKey);

      if (cachedVersion == null) return true;

      // Télécharger le JSON pour comparer la version
      final jsonUrl = _useDirectUrl
          ? _directJsonUrl
          : '$_backendUrl/api/pharmacies/latest';
      final response = await http
          .get(Uri.parse(jsonUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return false;

      final pharmaciesJson = jsonDecode(response.body);
      final remoteVersion = pharmaciesJson['version'] as int;

      return remoteVersion > cachedVersion;
    } catch (e) {
      return false;
    }
  }

  /// Efface le cache local
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_versionKey);
    // Cache effacé
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
