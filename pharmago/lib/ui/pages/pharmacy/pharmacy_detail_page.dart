import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/location_service.dart' as loc_service;
import '../../../utils/polyline_service.dart';
import '../navigation/yango_navigation_page.dart';

class PharmacyDetailPage extends StatefulWidget {
  final String pharmacyId;
  final String name;
  final String address;
  final bool isOpen;
  final double distanceKm;
  final double lat;
  final double lng;

  const PharmacyDetailPage({
    super.key,
    required this.pharmacyId,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.distanceKm,
    required this.lat,
    required this.lng,
  });

  @override
  State<PharmacyDetailPage> createState() => _PharmacyDetailPageState();
}

class _PharmacyDetailPageState extends State<PharmacyDetailPage> {
  final loc_service.LocationService _locationService =
      loc_service.LocationService();
  GoogleMapController? _mapController;
  Position? _userPosition;
  StreamSubscription<Position>? _posSub;
  BitmapDescriptor? _pharmacyIcon;
  BitmapDescriptor? _userIcon;
  String? _darkMapStyle;

  // Nouvelles variables pour polyline
  List<LatLng> routePoints = [];
  Set<Polyline> polylines = {};
  bool loadingPolyline = true;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadCustomIcons();
    _initLocation();
  }

  Future<void> _loadMapStyle() async {
    try {
      _darkMapStyle = await rootBundle.loadString(
        'assets/map_styles/dark.json',
      );
    } catch (e) {
      debugPrint('Erreur chargement style map: $e');
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      // Icône pharmacie personnalisée (si disponible)
      _pharmacyIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/icons/pharmacy_pin.png',
      );
    } catch (e) {
      // Fallback sur l'icône par défaut
      _pharmacyIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      debugPrint('Icône pharmacie non trouvée, utilisation icône par défaut');
    }

    // Icône utilisateur
    _userIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
  }

  Future<void> _initLocation() async {
    try {
      debugPrint('🔍 Début _initLocation');

      // Vérifier si le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📡 Service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        if (mounted) {
          _showLocationDialog(
            'GPS désactivé',
            'Sur SIMULATEUR iOS :\n1. Menu Features → Location → Custom Location\n2. Entrez : Lat 5.345317, Lon -4.024429\n\nSur APPAREIL RÉEL :\n1. Réglages → Confidentialité → Localisation\n2. Activez le service de localisation',
            onConfirm: () => Geolocator.openLocationSettings(),
            confirmText: 'Ouvrir paramètres',
          );
        }
        return;
      }

      // Vérifier l'état de la permission AVANT de demander
      final currentPermission = await Geolocator.checkPermission();
      debugPrint('🔐 Permission actuelle: $currentPermission');

      // Demander la permission
      final hasPermission = await _locationService.requestPermission();
      debugPrint('✅ Permission accordée: $hasPermission');

      if (!hasPermission) {
        if (mounted) {
          _showLocationDialog(
            'Permission refusée',
            'Pour utiliser cette fonctionnalité :\n\n1. Appuyez sur "Ouvrir paramètres"\n2. Recherchez "Localisation" ou "Position"\n3. Activez l\'accès à la localisation pour PharmaGo\n4. Revenez à l\'application',
            onConfirm: () => Geolocator.openAppSettings(),
            confirmText: 'Ouvrir paramètres',
          );
        }
        return;
      }

      // Récupérer la position
      debugPrint('📍 Tentative de récupération de la position...');
      final pos = await _locationService.getCurrentPosition();
      debugPrint('✅ Position récupérée: ${pos.latitude}, ${pos.longitude}');

      if (mounted) {
        setState(() => _userPosition = pos);

        // Charger la route polyline
        await _loadRoute();

        // Mettre à jour la caméra pour montrer les deux markers
        Future.delayed(const Duration(milliseconds: 500), () {
          _fitCameraToPolyline();
        });

        // Stream pour suivi en temps réel
        _posSub = _locationService.getPositionStream().listen((p) {
          if (mounted) {
            setState(() => _userPosition = p);
          }
        });
      }
    } on loc_service.PermissionDeniedException catch (e) {
      debugPrint('❌ Permission refusée: $e');
      if (mounted) {
        _showLocationDialog(
          'Permission requise',
          'Pour activer la localisation :\n\n1. Appuyez sur "Ouvrir paramètres" ci-dessous\n2. Trouvez "Localisation" dans les paramètres\n3. Activez la permission pour PharmaGo\n4. Retournez dans l\'application',
          onConfirm: () => Geolocator.openAppSettings(),
          confirmText: 'Ouvrir paramètres',
        );
      }
    } on loc_service.LocationServiceDisabledException catch (e) {
      debugPrint('❌ Service désactivé: $e');
      if (mounted) {
        _showLocationDialog(
          'GPS désactivé',
          'Sur SIMULATEUR iOS :\n1. Menu Features → Location → Custom Location\n2. Entrez : Lat 5.345317, Lon -4.024429\n\nSur APPAREIL RÉEL :\n1. Appuyez sur "Activer le GPS"\n2. Activez le service de localisation',
          onConfirm: () => Geolocator.openLocationSettings(),
          confirmText: 'Activer le GPS',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur localisation: $e');
      debugPrint('Type erreur: ${e.runtimeType}');
      // Ne rien afficher, la carte fonctionnera sans position utilisateur
    }
  }

  void _showLocationDialog(
    String title,
    String message, {
    VoidCallback? onConfirm,
    String confirmText = 'OK',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Plus tard',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRoute() async {
    if (_userPosition == null) return;

    try {
      debugPrint('🛣️ Chargement de la route...');
      const apiKey = "AIzaSyCYI5_sNO22IdUx37pupt4p67JyiP_56hg";
      final service = PolylineService(apiKey);

      final user = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final dest = LatLng(widget.lat, widget.lng);

      routePoints = await service.getRoutePolyline(
        origin: user,
        destination: dest,
      );
      debugPrint('✅ Route chargée: ${routePoints.length} points');

      polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          width: 6,
          color: const Color(0xFF4DB6AC),
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      };

      if (mounted) {
        setState(() => loadingPolyline = false);
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement route: $e');
      if (mounted) {
        setState(() => loadingPolyline = false);
      }
    }
  }

  void _updateCameraToShowBothMarkers() {
    if (_mapController == null || _userPosition == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _userPosition!.latitude < widget.lat
            ? _userPosition!.latitude
            : widget.lat,
        _userPosition!.longitude < widget.lng
            ? _userPosition!.longitude
            : widget.lng,
      ),
      northeast: LatLng(
        _userPosition!.latitude > widget.lat
            ? _userPosition!.latitude
            : widget.lat,
        _userPosition!.longitude > widget.lng
            ? _userPosition!.longitude
            : widget.lng,
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _fitCameraToPolyline() async {
    if (routePoints.isEmpty || _mapController == null) {
      // Fallback sur la méthode classique
      _updateCameraToShowBothMarkers();
      return;
    }

    final bounds = _createBounds(routePoints);
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    double x0 = points.first.latitude;
    double x1 = points.first.latitude;
    double y0 = points.first.longitude;
    double y1 = points.first.longitude;

    for (LatLng p in points) {
      if (p.latitude > x1) x1 = p.latitude;
      if (p.latitude < x0) x0 = p.latitude;
      if (p.longitude > y1) y1 = p.longitude;
      if (p.longitude < y0) y0 = p.longitude;
    }

    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // GOOGLE MAP en plein écran
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.lat, widget.lng),
                zoom: 13.0,
              ),
              mapType: MapType.normal,
              style: _darkMapStyle,
              polylines: polylines,
              onMapCreated: (controller) {
                debugPrint('🗺️ GoogleMap créée');
                _mapController = controller;

                // Appliquer le style dark après création
                if (_darkMapStyle != null) {
                  controller.setMapStyle(_darkMapStyle);
                }

                // Ajuster la caméra après un délai
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted) {
                    if (routePoints.isNotEmpty) {
                      _fitCameraToPolyline();
                    } else if (_userPosition != null) {
                      _updateCameraToShowBothMarkers();
                    }
                  }
                });
              },
              markers: {
                Marker(
                  markerId: const MarkerId("pharmacy"),
                  position: LatLng(widget.lat, widget.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: widget.name,
                    snippet: widget.address,
                  ),
                ),
                if (_userPosition != null)
                  Marker(
                    markerId: const MarkerId("user"),
                    position: LatLng(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                    infoWindow: const InfoWindow(title: "Votre position"),
                  ),
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
              padding: const EdgeInsets.only(top: 280, bottom: 100),
            ),

            // CARD INFO flottante en haut
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header avec bouton retour
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Détails de la pharmacie",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Card de détails
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildPharmacyCard(),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // BOUTON NAVIGATION flottant en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4DB6AC).withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        // Utiliser position réelle ou position par défaut (simulateur)
                        final LatLng userStart;

                        if (_userPosition != null) {
                          userStart = LatLng(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                          );
                        } else {
                          // Position par défaut proche de la pharmacie (pour simulateur)
                          debugPrint(
                            '⚠️ Pas de position GPS, utilisation position par défaut',
                          );
                          userStart = LatLng(
                            widget.lat + 0.01, // ~1km au nord
                            widget.lng + 0.01,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Position GPS non disponible. Utilisation position simulée.',
                              ),
                              backgroundColor: Colors.orange.shade700,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }

                        // Navigation vers YangoNavigationPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YangoNavigationPage(
                              userStart: userStart,
                              destination: LatLng(widget.lat, widget.lng),
                              destinationName: widget.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Démarrer la navigation",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Badge STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isOpen
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isOpen
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.isOpen ? "Ouvert" : "Fermé",
                  style: TextStyle(
                    color: widget.isOpen
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Badge DISTANCE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4DB6AC).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF4DB6AC),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${widget.distanceKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: Color(0xFF4DB6AC),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Adresse
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.address,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Téléphone
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              const Text(
                "42572779",
                style: TextStyle(
                  color: Color(0xFF26A69A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
