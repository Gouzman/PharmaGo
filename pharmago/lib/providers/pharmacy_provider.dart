import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacy.dart';
import '../services/pharmacy_data_service.dart';
import '../utils/pharmacy_distance.dart';

/// Provider pour gérer l'état des pharmacies dans l'application
class PharmacyProvider extends ChangeNotifier {
  final PharmacyDataService _dataService = PharmacyDataService();

  List<Pharmacy> _pharmacies = [];
  Position? _userPosition;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSync;

  // Getters
  List<Pharmacy> get pharmacies => _pharmacies;
  List<Pharmacy> get nearbyPharmacies => _getNearbyPharmacies();
  List<Pharmacy> get guardPharmacies =>
      _pharmacies.where((p) => p.isGuard).toList();
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  Position? get userPosition => _userPosition;

  /// Charge les pharmacies (cache ou backend)
  Future<void> loadPharmacies({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dataService.loadPharmacies(
        forceRefresh: forceRefresh,
      );

      if (data != null) {
        _pharmacies = data.pharmacies;
        _lastSync = data.generatedAt;
        debugPrint('✅ ${_pharmacies.length} pharmacies chargées');
      } else {
        _error = 'Impossible de charger les pharmacies';
        debugPrint('❌ Échec du chargement');
      }
    } catch (e, stack) {
      _error = 'Erreur: $e';
      debugPrint('❌ Erreur loadPharmacies: $e');
      debugPrint('Stack trace: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronise avec le backend
  Future<void> syncPharmacies() async {
    _isSyncing = true;
    notifyListeners();

    try {
      await loadPharmacies(forceRefresh: true);
      debugPrint('✅ Synchronisation terminée');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Vérifie s'il y a une mise à jour disponible
  Future<bool> checkForUpdates() async {
    return await _dataService.hasUpdate();
  }

  /// Met à jour la position de l'utilisateur
  void updateUserPosition(Position position) {
    _userPosition = position;
    notifyListeners();
  }

  /// Récupère les pharmacies à proximité (< 2km)
  /// Applique le filtrage par distance et supprime les doublons OSM
  List<Pharmacy> _getNearbyPharmacies() {
    if (_userPosition == null) return _pharmacies;

    // Étape 1 : Filtrer strictement par distance (≤ 2000m)
    final nearby = _filterByDistance(_pharmacies, _userPosition!);

    // Étape 2 : Supprimer les doublons OSM
    final deduplicated = _removeDuplicates(nearby, _userPosition!);

    // Étape 3 : Trier par distance
    return deduplicated..sort((a, b) {
      final distA = PharmacyDistance.distanceInMeters(
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
        pharmacyLat: a.lat,
        pharmacyLng: a.lng,
      );
      final distB = PharmacyDistance.distanceInMeters(
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
        pharmacyLat: b.lat,
        pharmacyLng: b.lng,
      );
      return distA.compareTo(distB);
    });
  }

  /// Filtre les pharmacies situées dans un rayon strict de 2 km
  List<Pharmacy> _filterByDistance(
    List<Pharmacy> pharmacies,
    Position userPosition,
  ) {
    return pharmacies.where((p) {
      final distance = PharmacyDistance.distanceInMeters(
        userLat: userPosition.latitude,
        userLng: userPosition.longitude,
        pharmacyLat: p.lat,
        pharmacyLng: p.lng,
      );
      return distance <= 2000.0; // 2 km strict
    }).toList();
  }

  /// Supprime les doublons OSM (même pharmacie avec coordonnées proches)
  ///
  /// Règles de déduplication :
  /// - Nom identique (normalisé : lowercase, trim)
  /// - Distance entre les points < 30 mètres
  ///
  /// Priorité de conservation :
  /// 1. Pharmacie de garde
  /// 2. Pharmacie ouverte
  /// 3. Première trouvée
  List<Pharmacy> _removeDuplicates(
    List<Pharmacy> pharmacies,
    Position userPosition,
  ) {
    if (pharmacies.isEmpty) return pharmacies;

    final Map<String, List<Pharmacy>> groups = {};

    // Grouper les pharmacies par nom normalisé
    for (final pharmacy in pharmacies) {
      final normalizedName = pharmacy.name.toLowerCase().trim();
      groups.putIfAbsent(normalizedName, () => []).add(pharmacy);
    }

    final List<Pharmacy> result = [];

    // Pour chaque groupe de pharmacies avec le même nom
    for (final group in groups.values) {
      if (group.length == 1) {
        // Pas de doublon potentiel
        result.add(group.first);
      } else {
        // Possibles doublons : vérifier la distance entre les points
        final List<Pharmacy> uniquePharmacies = [];

        for (final pharmacy in group) {
          bool isDuplicate = false;

          // Vérifier si cette pharmacie est un doublon d'une déjà ajoutée
          for (final existing in uniquePharmacies) {
            final distance = PharmacyDistance.distanceInMeters(
              userLat: pharmacy.lat,
              userLng: pharmacy.lng,
              pharmacyLat: existing.lat,
              pharmacyLng: existing.lng,
            );

            // Si distance < 30m, c'est probablement un doublon OSM
            if (distance < 30.0) {
              isDuplicate = true;

              // Remplacer l'existant si la nouvelle est meilleure
              if (_shouldReplace(existing, pharmacy)) {
                uniquePharmacies.remove(existing);
                uniquePharmacies.add(pharmacy);
              }
              break;
            }
          }

          if (!isDuplicate) {
            uniquePharmacies.add(pharmacy);
          }
        }

        result.addAll(uniquePharmacies);
      }
    }

    return result;
  }

  /// Détermine quelle pharmacie conserver en cas de doublon
  ///
  /// Priorité :
  /// 1. Pharmacie de garde > non garde
  /// 2. Pharmacie ouverte > fermée
  /// 3. Conserver l'existante (première trouvée)
  bool _shouldReplace(Pharmacy existing, Pharmacy candidate) {
    // Priorité 1 : garde
    if (candidate.isGuard && !existing.isGuard) return true;
    if (existing.isGuard && !candidate.isGuard) return false;

    // Priorité 2 : ouverte
    if (candidate.isOpenNow && !existing.isOpenNow) return true;
    if (existing.isOpenNow && !candidate.isOpenNow) return false;

    // Par défaut, garder l'existante
    return false;
  }

  /// Recherche des pharmacies par commune
  List<Pharmacy> getByCommune(String commune) {
    return _pharmacies
        .where((p) => p.commune.toLowerCase() == commune.toLowerCase())
        .toList();
  }

  /// Recherche des pharmacies par quartier
  List<Pharmacy> getByQuartier(String quartier) {
    return _pharmacies
        .where((p) => p.quartier.toLowerCase() == quartier.toLowerCase())
        .toList();
  }

  /// Récupère une pharmacie par ID
  Pharmacy? getPharmacyById(String id) {
    try {
      return _pharmacies.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Efface le cache
  Future<void> clearCache() async {
    await _dataService.clearCache();
    _pharmacies = [];
    _lastSync = null;
    notifyListeners();
  }
}
