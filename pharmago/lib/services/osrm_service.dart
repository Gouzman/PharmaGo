import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Service OSRM pour calcul d'itinéraires gratuit
/// Utilise l'API publique OSRM (OpenStreetMap Routing Machine)
class OSRMService {
  final Dio _dio = Dio();

  // URL de l'API OSRM publique
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Calcule un itinéraire entre deux points
  /// Retourne une liste de points LatLng formant la route
  Future<OSRMRoute?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // Format OSRM : longitude,latitude
      final url =
          '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final response = await _dio.get(
        url,
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Extraire la géométrie
          final geometry = route['geometry']['coordinates'] as List;
          final points = geometry.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          // Extraire distance et durée
          final distance = (route['distance'] as num).toDouble(); // en mètres
          final duration = (route['duration'] as num).toDouble(); // en secondes

          return OSRMRoute(
            points: points,
            distanceMeters: distance,
            durationSeconds: duration,
          );
        }
      }

      return null;
    } catch (e) {
      // Erreur OSRM: $e
      return null;
    }
  }

  /// Obtient des informations de navigation détaillées
  Future<List<OSRMStep>> getSteps({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final url =
          '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final response = await _dio.get(
        url,
        queryParameters: {
          'geometries': 'geojson',
          'steps': 'true',
          'overview': 'full',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List;

          final steps = <OSRMStep>[];
          for (var leg in legs) {
            final legSteps = leg['steps'] as List;
            for (var step in legSteps) {
              steps.add(
                OSRMStep(
                  instruction: step['maneuver']['instruction'] ?? '',
                  distance: (step['distance'] as num).toDouble(),
                  duration: (step['duration'] as num).toDouble(),
                ),
              );
            }
          }

          return steps;
        }
      }

      return [];
    } catch (e) {
      // Erreur OSRM steps: $e
      return [];
    }
  }
}

/// Modèle pour une route OSRM
class OSRMRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  OSRMRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Distance formatée en km
  String get distanceFormatted {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Durée formatée en minutes
  String get durationFormatted {
    final minutes = (durationSeconds / 60).round();
    return '$minutes min';
  }
}

/// Modèle pour une étape de navigation
class OSRMStep {
  final String instruction;
  final double distance;
  final double duration;

  OSRMStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });
}
