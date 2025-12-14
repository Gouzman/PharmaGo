import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// NavigationPage - Navigation en temps réel style Yango Maps / Uber
/// Interface complète avec curseur animé, polyline jaune, vue 3D, dark mode
class YangoNavigationPage extends StatefulWidget {
  final LatLng userStart;
  final LatLng destination;
  final String destinationName;

  const YangoNavigationPage({
    super.key,
    required this.userStart,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<YangoNavigationPage> createState() => _YangoNavigationPageState();
}

class _YangoNavigationPageState extends State<YangoNavigationPage>
    with TickerProviderStateMixin {
  // ========== CONTRÔLEURS ==========
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  AnimationController? _cursorAnimationController;
  Animation<double>? _cursorLatAnimation;
  Animation<double>? _cursorLngAnimation;

  // ========== POSITION UTILISATEUR ==========
  LatLng? _currentUserPosition;
  LatLng? _previousUserPosition;
  double _currentHeading = 0.0; // Direction GPS (boussole)
  double _currentSpeed = 0.0; // Vitesse m/s

  // ========== CURSEUR DYNAMIQUE ==========
  LatLng? _dynamicCursorPosition; // Position animée du curseur sur la route
  double _cursorRotation = 0.0; // Rotation du curseur selon la route

  // ========== ROUTE & POLYLINE ==========
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // ========== NAVIGATION DATA ==========
  double _distanceMeters = 0.0;
  int _durationSeconds = 0;
  String _nextTurnIcon = "straight";
  double _distanceToNextTurn = 0.0;
  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;

  // ========== STYLE & ICONS ==========
  String? _darkMapStyle;
  BitmapDescriptor? _cursorIcon; // Flèche navigation
  BitmapDescriptor? _destinationIcon;

  // ========== LOADING ==========
  bool _isLoadingRoute = true;

  // ========== GOOGLE MAPS API KEY ==========
  static const String _apiKey = "AIzaSyCYI5_sNO22IdUx37pupt4p67JyiP_56hg";

  @override
  void initState() {
    super.initState();
    _currentUserPosition = widget.userStart;
    _dynamicCursorPosition = widget.userStart;

    // Animation controller pour le curseur (mouvement fluide)
    _cursorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadMapStyle();
    _loadCustomIcons();
    _fetchRoute();
    _startPositionTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    _cursorAnimationController?.dispose();
    super.dispose();
  }

  // ========================================
  // 📌 1. CHARGEMENT DU STYLE DARK MODE
  // ========================================
  Future<void> _loadMapStyle() async {
    try {
      _darkMapStyle = await rootBundle.loadString(
        'assets/map_styles/dark.json',
      );
      debugPrint('✅ Style dark map chargé');
    } catch (e) {
      debugPrint('❌ Erreur chargement style: $e');
    }
  }

  // ========================================
  // 📌 2. CHARGEMENT DES ICÔNES CUSTOM
  // ========================================
  Future<void> _loadCustomIcons() async {
    try {
      // Icône curseur navigation (flèche/triangle jaune)
      _cursorIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/arrow_navigation.png',
      );
    } catch (e) {
      debugPrint(
        '⚠️ arrow_navigation.png non trouvé, création curseur par défaut',
      );
      // Curseur par défaut orange
      _cursorIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      );
    }

    try {
      // Icône destination
      _destinationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/icons/pharmacy_pin.png',
      );
    } catch (e) {
      debugPrint(
        '⚠️ pharmacy_pin.png non trouvé, utilisation icône par défaut',
      );
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
    }

    _updateMarkers();
  }

  // ========================================
  // 📌 3. RÉCUPÉRATION DE LA ROUTE (GOOGLE DIRECTIONS API)
  // ========================================
  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      final origin =
          '${widget.userStart.latitude},${widget.userStart.longitude}';
      final dest =
          '${widget.destination.latitude},${widget.destination.longitude}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$origin&destination=$dest&mode=driving&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extraction des données
          _distanceMeters = (leg['distance']['value'] as num).toDouble();
          _durationSeconds = leg['duration']['value'] as int;

          // Décodage de la polyline
          final encodedPolyline = route['overview_polyline']['points'];
          _routePoints = _decodePolyline(encodedPolyline);

          // Extraction des steps pour les instructions
          _steps = (leg['steps'] as List).map((step) {
            return NavigationStep(
              instruction: _cleanHtmlInstruction(step['html_instructions']),
              distance: (step['distance']['value'] as num).toDouble(),
              duration: step['duration']['value'] as int,
              maneuver: step['maneuver'] ?? 'straight',
              startLocation: LatLng(
                step['start_location']['lat'],
                step['start_location']['lng'],
              ),
              endLocation: LatLng(
                step['end_location']['lat'],
                step['end_location']['lng'],
              ),
            );
          }).toList();

          // Mise à jour de la polyline avec couleurs de trafic
          _updatePolyline();

          // Mise à jour instruction initiale
          if (_steps.isNotEmpty) {
            _nextTurnIcon = _steps[0].maneuver;
            _distanceToNextTurn = _steps[0].distance;
          }

          debugPrint(
            '✅ Route chargée: ${_routePoints.length} points, ${_steps.length} étapes',
          );
        } else {
          debugPrint('❌ Aucune route trouvée: ${data['status']}');
        }
      } else {
        debugPrint('❌ Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur fetch route: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  // ========================================
  // 📌 4. DÉCODAGE POLYLINE GOOGLE
  // ========================================
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // ========================================
  // 📌 5. NETTOYAGE DES INSTRUCTIONS HTML
  // ========================================
  String _cleanHtmlInstruction(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }

  // ========================================
  // 📌 6. MISE À JOUR POLYLINE STYLE YANGO (JAUNE + FOND GRIS)
  // ========================================
  void _updatePolyline() {
    if (_routePoints.isEmpty) return;

    final polylineList = <Polyline>[];

    // POLYLINE 1 : Fond gris (underlay) - width 12
    polylineList.add(
      Polyline(
        polylineId: const PolylineId('route_underlay'),
        points: _routePoints,
        color: const Color(0xFF424242), // Gris foncé
        width: 12,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    // POLYLINE 2 : Route principale jaune/orange (overlay) - width 8
    polylineList.add(
      Polyline(
        polylineId: const PolylineId('route_main'),
        points: _routePoints,
        color: const Color(0xFFFFC107), // Jaune Yango
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    setState(() {
      _polylines = polylineList.toSet();
    });
  }

  // ========================================
  // 📌 7. SUPPRIMÉ - Plus de couleur de trafic multicolore
  // ========================================

  // ========================================
  // 📌 8. SUIVI GPS EN TEMPS RÉEL
  // ========================================
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

  // ========================================
  // 📌 9. TRAITEMENT MISE À JOUR POSITION GPS
  // ========================================
  void _onPositionUpdate(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);

    // Sauvegarde position précédente pour calcul heading
    _previousUserPosition = _currentUserPosition;

    // Calcul du heading (direction de déplacement)
    if (_previousUserPosition != null) {
      _currentHeading = _calculateBearing(_previousUserPosition!, newPosition);
    } else if (position.heading >= 0) {
      // Utiliser heading GPS si disponible
      _currentHeading = position.heading;
    }

    // Mise à jour position actuelle
    _currentUserPosition = newPosition;

    // Mise à jour de la vitesse
    _currentSpeed = position.speed;

    // Animation du curseur sur la route
    _animateCursor(newPosition);

    // Recalcul de la distance restante
    _updateNavigationData(newPosition);

    // Mise à jour de l'instruction courante
    _updateCurrentStep(newPosition);

    // Mise à jour de la caméra (vue 3D qui suit l'utilisateur)
    _updateCamera(newPosition);
  }

  // ========================================
  // 📌 10. ANIMATION CURSEUR SUR LA ROUTE (LERP SMOOTH)
  // ========================================
  void _animateCursor(LatLng targetPosition) {
    if (_dynamicCursorPosition == null) {
      setState(() {
        _dynamicCursorPosition = targetPosition;
        _updateMarkers();
      });
      return;
    }

    // Animation Tween pour mouvement fluide
    _cursorLatAnimation =
        Tween<double>(
          begin: _dynamicCursorPosition!.latitude,
          end: targetPosition.latitude,
        ).animate(
          CurvedAnimation(
            parent: _cursorAnimationController!,
            curve: Curves.linear,
          ),
        );

    _cursorLngAnimation =
        Tween<double>(
          begin: _dynamicCursorPosition!.longitude,
          end: targetPosition.longitude,
        ).animate(
          CurvedAnimation(
            parent: _cursorAnimationController!,
            curve: Curves.linear,
          ),
        );

    _cursorAnimationController!.addListener(() {
      if (_cursorLatAnimation != null && _cursorLngAnimation != null) {
        setState(() {
          _dynamicCursorPosition = LatLng(
            _cursorLatAnimation!.value,
            _cursorLngAnimation!.value,
          );

          // Calculer rotation du curseur selon la direction sur la route
          if (_previousUserPosition != null && _currentUserPosition != null) {
            _cursorRotation = _calculateBearing(
              _previousUserPosition!,
              _currentUserPosition!,
            );
          }

          _updateMarkers();
        });
      }
    });

    _cursorAnimationController!.forward(from: 0.0);
  } // ========================================

  // 📌 11. CALCUL DU BEARING (DIRECTION)
  // ========================================
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

  // ========================================
  // 📌 12. MISE À JOUR DES MARKERS (CURSEUR + DESTINATION)
  // ========================================
  void _updateMarkers() {
    final markers = <Marker>{};

    // Marker CURSEUR NAVIGATION (flèche animée sur la route)
    if (_dynamicCursorPosition != null && _cursorIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('navigation_cursor'),
          position: _dynamicCursorPosition!,
          icon: _cursorIcon!,
          rotation: _cursorRotation, // Rotation selon direction route
          anchor: const Offset(0.5, 0.5), // Centrer l'icône
          flat: true, // Important pour rotation fluide
          zIndex: 10, // Au-dessus de tout
        ),
      );
    }

    // Marker DESTINATION (pharmacie)
    if (_destinationIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination,
          icon: _destinationIcon!,
          infoWindow: InfoWindow(title: widget.destinationName),
          zIndex: 5,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // ========================================
  // 📌 13. MISE À JOUR DES DONNÉES DE NAVIGATION
  // ========================================
  void _updateNavigationData(LatLng currentPos) {
    // Calcul de la distance restante jusqu'à la destination
    _distanceMeters = _calculateDistance(currentPos, widget.destination);

    // Estimation du temps restant basé sur la vitesse actuelle
    if (_currentSpeed > 0) {
      _durationSeconds = (_distanceMeters / _currentSpeed).round();
    }

    setState(() {});
  }

  // ========================================
  // 📌 14. CALCUL DISTANCE HAVERSINE
  // ========================================
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000.0; // mètres

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

  // ========================================
  // 📌 15. MISE À JOUR DE L'ÉTAPE COURANTE
  // ========================================
  void _updateCurrentStep(LatLng currentPos) {
    if (_steps.isEmpty || _currentUserPosition == null) return;

    // Vérifier si on est passé à l'étape suivante
    for (int i = _currentStepIndex; i < _steps.length; i++) {
      final step = _steps[i];
      final distanceToStepEnd = _calculateDistance(
        currentPos,
        step.endLocation,
      );

      if (distanceToStepEnd < 30) {
        // On a atteint cette étape, passer à la suivante
        if (i + 1 < _steps.length) {
          setState(() {
            _currentStepIndex = i + 1;
            _nextTurnIcon = _steps[_currentStepIndex].maneuver;
            _distanceToNextTurn = _steps[_currentStepIndex].distance;
          });
        }
        break;
      } else if (i == _currentStepIndex) {
        // Mise à jour de la distance jusqu'à la prochaine action
        setState(() {
          _distanceToNextTurn = distanceToStepEnd;
        });
      }
    }
  }

  // ========================================
  // 📌 16. MISE À JOUR CAMÉRA MODE CONDUITE (VUE 3D TILT 60° + BEARING)
  // ========================================
  void _updateCamera(LatLng position) {
    if (_mapController == null) return;

    // Caméra qui suit l'utilisateur avec vue 3D oblique
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position, // Position utilisateur
          zoom: 17.5, // Zoom proche (17-18)
          bearing: _currentHeading, // Orientation selon direction GPS
          tilt: 60.0, // Vue oblique 3D (comme Yango/Uber)
        ),
      ),
    );
  }

  // ========================================
  // 📌 17. BUILD UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ========== GOOGLE MAP MODE NAVIGATION ==========
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.userStart,
              zoom: 17.5,
              bearing: 0,
              tilt: 60, // Vue 3D oblique
            ),
            mapType: MapType.normal,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            trafficEnabled: true, // Afficher le trafic réel
            buildingsEnabled: true, // Bâtiments 3D
            onMapCreated: (controller) {
              _mapController = controller;
              if (_darkMapStyle != null) {
                controller.setMapStyle(_darkMapStyle);
              }
            },
          ),

          // ========== OVERLAYS STYLE YANGO ==========
          SafeArea(
            child: Column(
              children: [
                // Top bubbles
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Bubble distance prochaine action (top-left)
                      _buildNextTurnBubble(),
                      const Spacer(),
                      // Bubble ETA (top-right)
                      _buildETABubble(),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom panel
                _buildBottomPanel(),
              ],
            ),
          ),

          // Loader initial
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

  // ========================================
  // 📌 18. BUBBLE PROCHAINE ACTION (TOP-LEFT) - STYLE YANGO BLEU
  // ========================================
  Widget _buildNextTurnBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF357AE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          Icon(_getManeuverIcon(_nextTurnIcon), color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            _distanceToNextTurn < 1000
                ? '${_distanceToNextTurn.round()} м'
                : '${(_distanceToNextTurn / 1000).toStringAsFixed(1)} км',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📌 19. INDICATEUR VITESSE (TOP-RIGHT) - STYLE YANGO
  // ========================================
  Widget _buildETABubble() {
    // Convertir vitesse m/s en km/h
    final speedKmh = (_currentSpeed * 3.6).round();
    final speedLimit = 60; // Limite simulée

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
          // Cercle limite vitesse (rouge)
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

  // ========================================
  // 📌 21. BOTTOM PANEL - STYLE YANGO HORIZONTAL
  // ========================================
  Widget _buildBottomPanel() {
    final distanceKm = (_distanceMeters / 1000).toStringAsFixed(0);
    final etaMinutes = (_durationSeconds / 60).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
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
          // Distance (14km)
          Text(
            '$distanceKm км',
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          // Temps vert (11:09 ou -12 min)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '−$etaMinutes мин',
              style: const TextStyle(
                color: Color(0xFF34A853),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Durée totale (28min)
          Text(
            '$etaMinutes мин',
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          // Bouton X
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

  // ========================================
  // 📌 23. ICÔNES MANŒUVRES
  // ========================================
  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_right;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_right;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      default:
        return Icons.straight;
    }
  }
}

// ========================================
// 📌 24. CLASSE NAVIGATION STEP
// ========================================
class NavigationStep {
  final String instruction;
  final double distance;
  final int duration;
  final String maneuver;
  final LatLng startLocation;
  final LatLng endLocation;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.startLocation,
    required this.endLocation,
  });
}
