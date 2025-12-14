import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/pharmacy_data_service.dart';

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

  /// Récupère les pharmacies à proximité (< 5km)
  List<Pharmacy> _getNearbyPharmacies() {
    if (_userPosition == null) return _pharmacies;

    return _pharmacies
        .where(
          (p) =>
              p.distanceFrom(
                _userPosition!.latitude,
                _userPosition!.longitude,
              ) <=
              5.0,
        )
        .toList()
      ..sort((a, b) {
        final distA = a.distanceFrom(
          _userPosition!.latitude,
          _userPosition!.longitude,
        );
        final distB = b.distanceFrom(
          _userPosition!.latitude,
          _userPosition!.longitude,
        );
        return distA.compareTo(distB);
      });
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
