import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/local_storage.dart';
import '../../widgets/walking_person_road_progress_bar.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Simulation du chargement (3 secondes)
    await Future.delayed(const Duration(seconds: 10));

    final done = await LocalStorage.hasUserData();

    if (!mounted) return;

    if (done) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Dégradé code
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFB5E6D1), // vert menthe (haut droite)
              Color(0xFFFBFCFD), // blanc cassé (milieu)
              Color(0xFF9BB1C0), // bleu grisé (bas gauche)
            ],
          ),
        ),

        // Logo centré
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ton logo - place ton fichier logo.png dans assets/logo/
              Image.asset('assets/logo/splash.png', width: 150, height: 150),
              const SizedBox(height: 16),

              // Texte optionnel comme ton image "MedInfo"
              const Text(
                "PharmaGo",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5276),
                ),
              ),

              const SizedBox(height: 40),

              // ✨ Walking Person Road Progress Bar Widget ✨
              // Animated progress bar with PNG image following curved road
              const WalkingPersonRoadProgressBar(
                duration: Duration(seconds: 10),
                imagePath: 'assets/images/walking_person.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
