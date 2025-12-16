import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/osrm_service.dart';

/// OSMNavigationPage - Navigation temps réel style Yango/Uber avec OpenStreetMap
/// Polyline colorée, curseur animé, panneau info, vitesse en temps réel
class OSMNavigationPage extends StatefulWidget {
  final LatLng userStart;
  final LatLng destination;
  final String destinationName;

  const OSMNavigationPage({
    super.key,
    required this.userStart,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<OSMNavigationPage> createState() => _OSMNavigationPageState();
}

class _OSMNavigationPageState extends State<OSMNavigationPage>
    with SingleTickerProviderStateMixin {
  // Contrôleurs
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  late AnimationController _cursorAnimationController;

  // Position & Navigation
  LatLng? _currentUserPosition;
  LatLng? _previousUserPosition;
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0; // m/s

  // Route
  List<LatLng> _routePoints = [];
  double _distanceMeters = 0.0;
  int _durationSeconds = 0;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _currentUserPosition = widget.userStart;

    _cursorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fetchRoute();
    _startPositionTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _cursorAnimationController.dispose();
    super.dispose();
  }

  /// Récupérer la route avec OSRM
  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      final osrmService = OSRMService();
      final route = await osrmService.getRoute(
        start: widget.userStart,
        end: widget.destination,
      );

      if (route != null && mounted) {
        setState(() {
          _routePoints = route.points;
          _distanceMeters = route.distanceMeters;
          _durationSeconds = route.durationSeconds.toInt();
          _isLoadingRoute = false;
        });

        // Ajuster la caméra pour voir toute la route
        _fitCameraToRoute();
      } else {
        setState(() => _isLoadingRoute = false);
      }
    } catch (e) {
      debugPrint('❌ Erreur route: $e');
      setState(() => _isLoadingRoute = false);
    }
  }

  /// Suivi GPS en temps réel
  void _startPositionTracking() {
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Mise à jour tous les 5m
          ),
        ).listen((Position position) {
          _onPositionUpdate(position);
        });
  }

  /// Traitement position GPS
  void _onPositionUpdate(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);

    _previousUserPosition = _currentUserPosition;

    // Calcul direction
    if (_previousUserPosition != null) {
      _currentHeading = _calculateBearing(_previousUserPosition!, newPosition);
    } else if (position.heading >= 0) {
      _currentHeading = position.heading;
    }

    setState(() {
      _currentUserPosition = newPosition;
      _currentSpeed = position.speed;
    });

    _updateNavigationData(newPosition);
    _updateCamera(newPosition);
  }

  /// Calcul bearing (direction)
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * math.pi / 180;
    final startLng = start.longitude * math.pi / 180;
    final endLat = end.latitude * math.pi / 180;
    final endLng = end.longitude * math.pi / 180;

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x =
        math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Mise à jour données navigation
  void _updateNavigationData(LatLng currentPos) {
    _distanceMeters = _calculateDistance(currentPos, widget.destination);

    if (_currentSpeed > 0) {
      _durationSeconds = (_distanceMeters / _currentSpeed).round();
    }
  }

  /// Distance Haversine
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000.0;

    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLat = (end.latitude - start.latitude) * math.pi / 180;
    final dLng = (end.longitude - start.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Ajuster caméra pour voir route
  void _fitCameraToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            ),
            padding: const EdgeInsets.all(80),
          ),
        );
      }
    });
  }

  /// Suivre utilisateur avec caméra
  void _updateCamera(LatLng position) {
    _mapController.move(position, 17.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte OSM
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

              // Polyline route (style Yango - fond gris + route jaune)
              if (_routePoints.isNotEmpty) ...[
                // Fond gris
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF424242),
                      strokeWidth: 12.0,
                    ),
                  ],
                ),
                // Route principale jaune
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFFFFC107),
                      strokeWidth: 8.0,
                    ),
                  ],
                ),
              ],

              // Markers
              MarkerLayer(
                markers: [
                  // Marker destination (pharmacie)
                  Marker(
                    point: widget.destination,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Color(0xFF4DB6AC),
                      size: 40,
                    ),
                  ),

                  // Marker utilisateur (curseur animé)
                  if (_currentUserPosition != null)
                    Marker(
                      point: _currentUserPosition!,
                      width: 50,
                      height: 50,
                      rotate: true,
                      child: Transform.rotate(
                        angle: _currentHeading * math.pi / 180,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Overlays UI
          SafeArea(
            child: Column(
              children: [
                // Top bar avec distance et vitesse
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildDistanceBubble(),
                      const Spacer(),
                      _buildSpeedBubble(),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom panel
                _buildBottomPanel(),
              ],
            ),
          ),

          // Loader
          if (_isLoadingRoute)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4DB6AC)),
                    SizedBox(height: 16),
                    Text(
                      'Calcul de l\'itinéraire...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bubble distance restante
  Widget _buildDistanceBubble() {
    final distanceKm = _distanceMeters / 1000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF357AE8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Bubble vitesse
  Widget _buildSpeedBubble() {
    final speedKmh = (_currentSpeed * 3.6).round();
    const speedLimit = 60;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Limite vitesse
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$speedLimit',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Vitesse actuelle
          Text(
            '$speedKmh',
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom panel style Yango
  Widget _buildBottomPanel() {
    final distanceKm = (_distanceMeters / 1000).toStringAsFixed(0);
    final etaMinutes = (_durationSeconds / 60).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Distance
          Text(
            '$distanceKm km',
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ETA badge vert
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF34A853),
                ),
                const SizedBox(width: 4),
                Text(
                  '$etaMinutes min',
                  style: const TextStyle(
                    color: Color(0xFF34A853),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Destination
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                widget.destinationName,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Bouton fermer
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF121212),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
