import 'package:go_router/go_router.dart';
import '../ui/pages/splash/splash_page.dart';
import '../ui/pages/onboarding/onboarding_page.dart';
import '../ui/pages/home/home_page.dart';
import '../ui/pages/pharmacy/pharmacy_detail_page.dart';
import '../ui/pages/gps/navigation_page.dart';
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
        return PharmacyDetailPage(pharmacyId: state.pathParameters['id']!);
      },
    ),

    GoRoute(
      path: '/gps/:id',
      builder: (_, state) {
        return NavigationPage(pharmacyId: state.pathParameters['id']!);
      },
    ),

    if (FeatureFlags.enableMedicationRequest)
      GoRoute(path: '/request', builder: (_, __) => MedicationRequestPage()),
  ],
);
