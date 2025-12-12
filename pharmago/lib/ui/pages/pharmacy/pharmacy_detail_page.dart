import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/location_service.dart' as loc_service;

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

        // Mettre à jour la caméra pour montrer les deux markers
        Future.delayed(const Duration(milliseconds: 500), () {
          _updateCameraToShowBothMarkers();
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
            color: Colors.white,
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
        child: Column(
          children: [
            // HEADER avec bouton retour
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  const SizedBox(width: 12),
                  const Text(
                    "Détails de la pharmacie",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // CARD INFO avec design dark premium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E1E1E), const Color(0xFF252525)],
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
                            color: const Color(
                              0xFF4DB6AC,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF4DB6AC,
                              ).withValues(alpha: 0.5),
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
                        const Icon(
                          Icons.phone_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
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
              ),
            ),

            const SizedBox(height: 20),

            // GOOGLE MAP avec style dark
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.lat, widget.lng),
                    zoom: 15.5,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_darkMapStyle != null) {
                      controller.setMapStyle(_darkMapStyle);
                    }
                  },
                  markers: {
                    if (_pharmacyIcon != null)
                      Marker(
                        markerId: const MarkerId("pharmacy"),
                        position: LatLng(widget.lat, widget.lng),
                        icon: _pharmacyIcon!,
                        infoWindow: InfoWindow(
                          title: widget.name,
                          snippet: widget.address,
                        ),
                      ),
                    if (_userPosition != null && _userIcon != null)
                      Marker(
                        markerId: const MarkerId("user"),
                        position: LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        icon: _userIcon!,
                        infoWindow: const InfoWindow(title: "Votre position"),
                      ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(12, 20),
                ),
              ),
            ),

            // BOUTON NAVIGATION avec gradient premium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF121212), const Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                      // TODO: Implémenter navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Navigation à implémenter'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
          ],
        ),
      ),
    );
  }
}
