import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/osrm_service.dart';

/// NavigationPage - Navigation en temps réel style Yango/Uber avec OSM
/// Affiche la position utilisateur, polyline, distance, ETA
class NavigationPage extends StatefulWidget {
  final LatLng userStart;
  final LatLng pharmacyPosition;
  final String pharmacyName;

  const NavigationPage({
    super.key,
    required this.userStart,
    required this.pharmacyPosition,
    required this.pharmacyName,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  // État
  Position? _currentUserPosition;
  List<LatLng> _routePoints = [];

  // Données navigation
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _loadInitialRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Démarrer le suivi GPS temps réel
  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('GPS désactivé');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission localisation refusée');
          return;
        }
      }

      // Position initiale
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentUserPosition = initialPosition;
        });
        _calculateDistanceAndETA();
      }

      // Stream temps réel
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update tous les 10m
            ),
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentUserPosition = position;
              });
              _calculateDistanceAndETA();
              _updateCameraPosition();
            }
          });
    } catch (e) {
      debugPrint('❌ Erreur tracking GPS: $e');
      _showError('Impossible de récupérer la position');
    }
  }

  /// Charger l'itinéraire initial avec OSRM
  Future<void> _loadInitialRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      final osrmService = OSRMService();
      final route = await osrmService.getRoute(
        start: widget.userStart,
        end: widget.pharmacyPosition,
      );

      if (mounted && route != null) {
        setState(() {
          _routePoints = route.points;
          _distanceKm = route.distanceMeters / 1000;
          _etaMinutes = (route.durationSeconds / 60).ceil();
          _isLoadingRoute = false;
        });

        _fitCameraToRoute();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement route: $e');
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        _showError('Impossible de charger l\'itinéraire');
      }
    }
  }

  /// Calculer distance et ETA avec Haversine
  void _calculateDistanceAndETA() {
    if (_currentUserPosition == null) return;

    final distanceMeters = Geolocator.distanceBetween(
      _currentUserPosition!.latitude,
      _currentUserPosition!.longitude,
      widget.pharmacyPosition.latitude,
      widget.pharmacyPosition.longitude,
    );

    final distanceKm = distanceMeters / 1000;
    final etaMinutes = (distanceKm / 35 * 60).ceil(); // 35 km/h vitesse moyenne

    setState(() {
      _distanceKm = distanceKm;
      _etaMinutes = etaMinutes;
    });
  }

  /// Ajuster la caméra pour afficher toute la route
  Future<void> _fitCameraToRoute() async {
    if (_routePoints.isEmpty) return;

    final bounds = _calculateBounds(_routePoints);

    await Future.delayed(const Duration(milliseconds: 300));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(bounds.$1, bounds.$2),
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Mettre à jour la position de la caméra en suivant l'utilisateur
  void _updateCameraPosition() {
    if (_currentUserPosition == null) return;

    _mapController.move(
      LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude),
      15.0,
    );
  }

  /// Calculer les bounds min/max pour la caméra
  (LatLng, LatLng) _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return (LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  /// Afficher une erreur
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // FLUTTER MAP (OSM) FULLSCREEN
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.userStart,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Tuiles OSM
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pharmago.app',
                ),

                // Polyline de la route
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: const Color(0xFF4DB6AC),
                        strokeWidth: 7.0,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Marker pharmacie
                    Marker(
                      point: widget.pharmacyPosition,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Color(0xFF4DB6AC),
                        size: 40,
                      ),
                    ),

                    // Marker utilisateur
                    if (_currentUserPosition != null)
                      Marker(
                        point: LatLng(
                          _currentUserPosition!.latitude,
                          _currentUserPosition!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // PANNEAU INFO EN HAUT (style Yango)
            _buildNavigationPanel(),

            // BOUTON ARRÊTER EN BAS
            _buildStopButton(),

            // LOADER pendant chargement route
            if (_isLoadingRoute)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4DB6AC)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Panneau d'informations en haut (Yango style)
  Widget _buildNavigationPanel() {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1E1E).withValues(alpha: 0.95),
              const Color(0xFF252525).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4DB6AC).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Color(0xFF4DB6AC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Navigation en cours',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Distance & ETA
            Row(
              children: [
                // Distance
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distance',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Color(0xFF4DB6AC),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ETA
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arrivée',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_etaMinutes min',
                          style: const TextStyle(
                            color: Color(0xFF4DB6AC),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nom destination
            Row(
              children: [
                const Icon(Icons.place, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.pharmacyName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton arrêter navigation
  Widget _buildStopButton() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Arrêter la navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
