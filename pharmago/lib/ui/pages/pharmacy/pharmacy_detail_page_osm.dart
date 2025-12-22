import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/pharmacy.dart';
import '../../../services/pharmacy_data_service.dart';
import '../../../services/osrm_service.dart';
import '../../../services/location_service.dart';
import '../../widgets/osm_map_widget.dart';
import 'package:geolocator/geolocator.dart';

/// Page de détail d'une pharmacie avec carte OSM et itinéraire OSRM
class PharmacyDetailPageOSM extends StatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailPageOSM({super.key, required this.pharmacy});

  @override
  State<PharmacyDetailPageOSM> createState() => _PharmacyDetailPageOSMState();
}

class _PharmacyDetailPageOSMState extends State<PharmacyDetailPageOSM> {
  final OSRMService _osrmService = OSRMService();
  final LocationService _locationService = LocationService();

  Position? _userPosition;
  OSRMRoute? _route;
  bool _isLoadingRoute = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Demander la permission
      final hasPermission = await _locationService.requestPermission();

      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Permission de localisation refusée';
          _isLoadingRoute = false;
        });
        return;
      }

      // Obtenir la position
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible d\'obtenir votre position';
          _isLoadingRoute = false;
        });
        return;
      }

      setState(() {
        _userPosition = position;
      });

      // Calculer l'itinéraire avec OSRM
      await _loadRoute();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _loadRoute() async {
    if (_userPosition == null) return;

    try {
      final route = await _osrmService.getRoute(
        start: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        end: LatLng(widget.pharmacy.lat, widget.pharmacy.lng),
      );

      setState(() {
        _route = route;
        _isLoadingRoute = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur calcul itinéraire: $e';
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte OSM avec itinéraire
          if (_userPosition != null && _route != null)
            OSMMapWidget(
              center: LatLng(widget.pharmacy.lat, widget.pharmacy.lng),
              zoom: 14,
              pharmacies: [widget.pharmacy],
              routePoints: _route!.points,
              userPosition: LatLng(
                _userPosition!.latitude,
                _userPosition!.longitude,
              ),
              showUserMarker: true,
            )
          else if (_isLoadingRoute)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeLocation,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else
            // Carte simple sans itinéraire
            OSMMapWidget(
              center: LatLng(widget.pharmacy.lat, widget.pharmacy.lng),
              zoom: 15,
              pharmacies: [widget.pharmacy],
            ),

          // Bouton retour
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Carte d'information en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de la pharmacie
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.pharmacy.isGuard
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_pharmacy,
                              color: widget.pharmacy.isGuard
                                  ? Colors.red
                                  : Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.pharmacy.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      widget.pharmacy.isOpenNow
                                          ? Icons.access_time
                                          : Icons.access_time_filled,
                                      size: 16,
                                      color: widget.pharmacy.isOpenNow
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.pharmacy.status,
                                      style: TextStyle(
                                        color: widget.pharmacy.isOpenNow
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.pharmacy.isGuard) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'DE GARDE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Adresse (afficher seulement si disponible)
                      if (widget.pharmacy.address.isNotEmpty ||
                          widget.pharmacy.quartier.isNotEmpty)
                        _InfoRow(
                          icon: Icons.location_on,
                          text: [
                            if (widget.pharmacy.address.isNotEmpty)
                              widget.pharmacy.address,
                            if (widget.pharmacy.quartier.isNotEmpty)
                              widget.pharmacy.quartier,
                          ].join(', '),
                          color: Colors.blue,
                        ),

                      if (widget.pharmacy.address.isNotEmpty ||
                          widget.pharmacy.quartier.isNotEmpty)
                        const SizedBox(height: 12),

                      // Téléphone
                      if (widget.pharmacy.phone.isNotEmpty)
                        _InfoRow(
                          icon: Icons.phone,
                          text: widget.pharmacy.phone,
                          color: Colors.green,
                        ),

                      // Distance et durée (si route disponible)
                      if (_route != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.directions_car,
                              text: _route!.distanceFormatted,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.access_time,
                              text: _route!.durationFormatted,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Appeler la pharmacie
                                // Implémenter l'appel téléphonique
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Appeler'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Ouvrir dans une app de navigation externe
                                // Implémenter l'ouverture dans Maps
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Y aller'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
