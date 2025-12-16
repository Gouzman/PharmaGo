import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../services/pharmacy_data_service.dart';
import '../ui/pages/splash/splash_page.dart';
import '../ui/pages/onboarding/onboarding_page.dart';
import '../ui/pages/home/home_page.dart';
import '../ui/pages/pharmacy/pharmacy_detail_page_osm.dart';
import '../ui/pages/gps/navigation_page.dart' as old_nav;
import '../ui/pages/navigation/osm_navigation_page.dart';
import '../config/feature_flags.dart';
import '../ui/pages/hidden/medication_request/request_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingPage()),
    GoRoute(path: '/home', builder: (_, __) => HomePage()),

    GoRoute(
      path: '/pharmacy/:id',
      builder: (_, state) {
        return PharmacyDetailPageOSM(
          pharmacy: Pharmacy(
            id: state.pathParameters['id']!,
            name: state.uri.queryParameters['name'] ?? 'Pharmacie',
            address:
                state.uri.queryParameters['address'] ??
                'Adresse non disponible',
            lat:
                double.tryParse(
                  state.uri.queryParameters['lat'] ?? '5.345317',
                ) ??
                5.345317,
            lng:
                double.tryParse(
                  state.uri.queryParameters['lng'] ?? '-4.024429',
                ) ??
                -4.024429,
            commune: state.uri.queryParameters['commune'] ?? '',
            quartier: state.uri.queryParameters['quartier'] ?? '',
            phone: state.uri.queryParameters['phone'] ?? '',
            assurances: [],
            isGuard: state.uri.queryParameters['isGuard'] == 'true',
            updatedAt: DateTime.now(),
          ),
        );
      },
    ),

    GoRoute(
      path: '/gps/:id',
      builder: (_, state) {
        return old_nav.NavigationPage(pharmacyId: state.pathParameters['id']!);
      },
    ),

    GoRoute(
      path: '/navigation',
      builder: (_, state) {
        // Récupérer les paramètres de la pharmacie
        final pharmacyName =
            state.uri.queryParameters['pharmacyName'] ?? 'Pharmacie';
        final pharmacyLat =
            double.tryParse(
              state.uri.queryParameters['pharmacyLat'] ?? '5.345317',
            ) ??
            5.345317;
        final pharmacyLng =
            double.tryParse(
              state.uri.queryParameters['pharmacyLng'] ?? '-4.024429',
            ) ??
            -4.024429;

        // Position de départ simulée (sera remplacée par GPS dans OSMNavigationPage)
        final userStart = LatLng(pharmacyLat + 0.01, pharmacyLng + 0.01);

        return OSMNavigationPage(
          userStart: userStart,
          destination: LatLng(pharmacyLat, pharmacyLng),
          destinationName: pharmacyName,
        );
      },
    ),

    if (FeatureFlags.enableMedicationRequest)
      GoRoute(path: '/request', builder: (_, __) => MedicationRequestPage()),
  ],
);
