import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/location_service.dart';

class LocationConsumerWidget extends StatefulWidget {
  final void Function(Position pos)? onPosition;
  const LocationConsumerWidget({this.onPosition, super.key});

  @override
  State<LocationConsumerWidget> createState() => _LocationConsumerWidgetState();
}

class _LocationConsumerWidgetState extends State<LocationConsumerWidget> {
  final LocationService _locService = LocationService();
  Position? _position;
  String? _error;
  StreamSubscription<Position>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _locService.getCurrentPosition();
      setState(() => _position = pos);
      widget.onPosition?.call(pos);

      // Optionally start a stream to follow user location (for navigation)
      _sub = _locService.getPositionStream().listen((p) {
        setState(() {
          _position = p;
        });
        widget.onPosition?.call(p);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        'Erreur localisation: $_error',
        style: const TextStyle(color: Colors.red),
      );
    }
    if (_position == null) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Text(
      'Localisation: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
    );
  }
}
