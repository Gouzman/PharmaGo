import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Page de test simple pour Google Maps
class TestMapPage extends StatefulWidget {
  const TestMapPage({super.key});

  @override
  State<TestMapPage> createState() => _TestMapPageState();
}

class _TestMapPageState extends State<TestMapPage> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Google Maps'),
        backgroundColor: const Color(0xFF4DB6AC),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(5.345317, -4.024429), // Abidjan
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          debugPrint('✅ Map créée avec succès');
        },
        markers: {
          const Marker(
            markerId: MarkerId('test'),
            position: LatLng(5.345317, -4.024429),
            infoWindow: InfoWindow(title: 'Test Marker'),
          ),
        },
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
