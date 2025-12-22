import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/pharmacy.dart';
import '../../services/pharmacy_data_service.dart';

/// Widget carte OpenStreetMap réutilisable
class OSMMapWidget extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<Pharmacy>? pharmacies;
  final List<LatLng>? routePoints;
  final Function(Pharmacy)? onPharmacyTap;
  final bool showUserMarker;
  final LatLng? userPosition;
  final bool enableInteraction;

  const OSMMapWidget({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.pharmacies,
    this.routePoints,
    this.onPharmacyTap,
    this.showUserMarker = true,
    this.userPosition,
    this.enableInteraction = true,
  });

  @override
  State<OSMMapWidget> createState() => _OSMMapWidgetState();
}

class _OSMMapWidgetState extends State<OSMMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    // Ajuster les bounds si une route est affichée
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    if (widget.routePoints == null || widget.routePoints!.isEmpty) return;

    final points = widget.routePoints!;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        interactionOptions: InteractionOptions(
          flags: widget.enableInteraction
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
      ),
      children: [
        // Couche de tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pharmago.app',
          maxZoom: 19,
          maxNativeZoom: 19,
        ),

        // Ligne de route (si présente)
        if (widget.routePoints != null && widget.routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints!,
                strokeWidth: 4.0,
                color: Colors.blue,
                borderColor: Colors.white,
                borderStrokeWidth: 1.0,
              ),
            ],
          ),

        // Marqueurs des pharmacies
        if (widget.pharmacies != null && widget.pharmacies!.isNotEmpty)
          MarkerLayer(
            markers: widget.pharmacies!.map((pharmacy) {
              return Marker(
                point: LatLng(pharmacy.lat, pharmacy.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onPharmacyTap != null) {
                      widget.onPharmacyTap!(pharmacy);
                    }
                  },
                  child: _buildPharmacyMarker(pharmacy),
                ),
              );
            }).toList(),
          ),

        // Marqueur utilisateur
        if (widget.showUserMarker && widget.userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.userPosition!,
                width: 50,
                height: 50,
                child: _buildUserMarker(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPharmacyMarker(Pharmacy pharmacy) {
    return Container(
      decoration: BoxDecoration(
        color: pharmacy.isGuard ? Colors.red : Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.local_pharmacy, color: Colors.white, size: 20),
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.my_location, color: Colors.white, size: 24),
    );
  }
}
