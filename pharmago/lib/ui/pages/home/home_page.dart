import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharmago/models/pharmacy.dart';
import 'package:pharmago/providers/pharmacy_provider.dart';
import 'package:pharmago/utils/location_service.dart';
import 'package:pharmago/utils/pharmacy_distance.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Attendre que le build soit terminé avant d'initialiser
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final pharmacyProvider = context.read<PharmacyProvider>();

    debugPrint('🚀 Initialisation HomePage...');

    // 🧪 MODE TEST : Position fixe à Abidjan (Plateau)
    final testPosition = Position(
      latitude: 5.316667, // Plateau, Abidjan
      longitude: -4.033333,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    pharmacyProvider.updateUserPosition(testPosition);
    debugPrint('✅ Position TEST fixée: Plateau, Abidjan (5.316667, -4.033333)');

    /* 
    // Code original avec géolocalisation réelle (à réactiver plus tard)
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (mounted) {
        pharmacyProvider.updateUserPosition(position);
        debugPrint('✅ Position: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible de récupérer la position: $e');
      debugPrint('ℹ️ Les pharmacies seront affichées sans filtre de distance');
    }
    */

    // Charger les pharmacies
    if (mounted) {
      debugPrint('📥 Chargement des pharmacies...');
      await pharmacyProvider.loadPharmacies();
      debugPrint('📊 Pharmacies loaded: ${pharmacyProvider.pharmacies.length}');
      debugPrint('📍 Nearby: ${pharmacyProvider.nearbyPharmacies.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _BottomNavBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB5E6D1),
              Color(0xFFFBFCFD),
              Color.fromARGB(255, 255, 255, 255),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Section fixe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black87,
                              child: Text(
                                "J",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Judicael Kobenan",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.map_outlined),
                            color: const Color(0xFF4DB6AC),
                            onPressed: () => context.push('/test-map'),
                            tooltip: 'Test Carte',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Consumer<PharmacyProvider>(
                            builder: (context, provider, _) {
                              return Stack(
                                children: [
                                  IconButton(
                                    icon: provider.isSyncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.refresh),
                                    onPressed: provider.isSyncing
                                        ? null
                                        : () async {
                                            await provider.syncPharmacies();
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '✅ Pharmacies mises à jour',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    tooltip: 'Actualiser',
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _AdCarousel(),
                    const SizedBox(height: 24),
                    Consumer<PharmacyProvider>(
                      builder: (context, provider, _) {
                        final nearbyCount = provider.nearbyPharmacies.length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Pharmacie à proximité",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$nearbyCount pharmacies · 0 - 5km",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              "Voir tout",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Section scrollable avec les pharmacies
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Consumer<PharmacyProvider>(
                    builder: (context, provider, _) {
                      // Afficher le loader pendant le chargement initial
                      if (provider.isLoading && provider.pharmacies.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF4DB6AC),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chargement des pharmacies...',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Afficher un message si aucune pharmacie
                      if (provider.pharmacies.isEmpty) {
                        debugPrint('⚠️ Affichage: Aucune pharmacie disponible');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_pharmacy_outlined,
                                size: 64,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune pharmacie disponible\nError: ${provider.error ?? "N/A"}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => provider.syncPharmacies(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4DB6AC),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Afficher les pharmacies à proximité
                      final nearbyPharmacies = provider.nearbyPharmacies;
                      final userPosition = provider.userPosition;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...nearbyPharmacies.map((pharmacy) {
                              final distanceText = userPosition != null
                                  ? PharmacyDistance.formatDistance(
                                      userLat: userPosition.latitude,
                                      userLng: userPosition.longitude,
                                      pharmacyLat: pharmacy.lat,
                                      pharmacyLng: pharmacy.lng,
                                    )
                                  : '0 m';

                              final distance = userPosition != null
                                  ? PharmacyDistance.distanceInMeters(
                                      userLat: userPosition.latitude,
                                      userLng: userPosition.longitude,
                                      pharmacyLat: pharmacy.lat,
                                      pharmacyLng: pharmacy.lng,
                                    )
                                  : 0.0;

                              // Construire la ligne d'adresse uniquement si données disponibles
                              String addressLine = '';
                              if (pharmacy.address.isNotEmpty &&
                                  pharmacy.phone.isNotEmpty) {
                                addressLine =
                                    '${pharmacy.address} · ${pharmacy.phone}';
                              } else if (pharmacy.address.isNotEmpty) {
                                addressLine = pharmacy.address;
                              } else if (pharmacy.phone.isNotEmpty) {
                                addressLine = pharmacy.phone;
                              }
                              // Si rien n'est disponible, afficher le quartier ou commune
                              if (addressLine.isEmpty) {
                                addressLine = pharmacy.quartier.isNotEmpty
                                    ? pharmacy.quartier
                                    : pharmacy.commune;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PharmacyCard(
                                  name: pharmacy.name,
                                  subtitle: pharmacy.quartier.isNotEmpty
                                      ? pharmacy.quartier
                                      : pharmacy.commune,
                                  address: addressLine,
                                  status: pharmacy.status,
                                  closingTime: pharmacy.closingTimeText,
                                  distance: distanceText,
                                  isOpen: pharmacy.isOpenNow,
                                  isGuard: pharmacy.isGuard,
                                  onTap: () {},
                                  onDetailsPressed: () {
                                    context.push(
                                      '/pharmacy/${pharmacy.id}?name=${Uri.encodeComponent(pharmacy.name)}&address=${Uri.encodeComponent(pharmacy.address)}&isOpen=${pharmacy.isOpenNow}&distance=${distance.toStringAsFixed(1)}&lat=${pharmacy.lat}&lng=${pharmacy.lng}',
                                    );
                                  },
                                  onNavigationPressed: () {
                                    context.push(
                                      '/navigation?pharmacyName=${Uri.encodeComponent(pharmacy.name)}&pharmacyLat=${pharmacy.lat}&pharmacyLng=${pharmacy.lng}',
                                    );
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdCarousel extends StatefulWidget {
  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _ads = [
    {
      'title': 'Profitez de -20%',
      'subtitle': 'Sur tous vos médicaments',
      'color': Color(0xFF4DB6AC),
      'icon': Icons.local_offer,
    },
    {
      'title': 'Livraison Gratuite',
      'subtitle': 'Pour toute commande supérieure à 10 000 Fcfa',
      'color': Color(0xFF66BB6A),
      'icon': Icons.local_shipping,
    },
    {
      'title': 'Consultation en ligne',
      'subtitle': 'Parlez à un pharmacien 24/7',
      'color': Color(0xFF5A7C8E),
      'icon': Icons.video_call,
    },
    {
      'title': 'Programme Fidélité',
      'subtitle': 'Gagnez des points à chaque achat',
      'color': Color(0xFFFF7043),
      'icon': Icons.card_giftcard,
    },
    {
      'title': 'Rappel Médicaments',
      'subtitle': 'Ne manquez jamais une dose',
      'color': Color(0xFF7E57C2),
      'icon': Icons.alarm,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              final ad = _ads[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ad['color'] as Color,
                      (ad['color'] as Color).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (ad['color'] as Color).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ad['title'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ad['subtitle'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ad['icon'] as IconData,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _ads.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Color(0xFF4DB6AC)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String address;
  final String status;
  final String closingTime;
  final String distance;
  final bool isOpen;
  final bool isGuard;
  final VoidCallback onTap;
  final VoidCallback onDetailsPressed;
  final VoidCallback onNavigationPressed;

  const _PharmacyCard({
    required this.name,
    required this.subtitle,
    required this.address,
    required this.status,
    required this.closingTime,
    required this.distance,
    required this.isOpen,
    this.isGuard = false,
    required this.onTap,
    required this.onDetailsPressed,
    required this.onNavigationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isGuard
              ? Border.all(color: const Color(0xFFFF6F00), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGuard
                    ? const Color(0xFFFF6F00)
                    : const Color(0xFF2D5F4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGuard ? Icons.medical_services : Icons.local_pharmacy,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isGuard)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'GARDE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4DB6AC,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF4DB6AC),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4DB6AC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOpen ? Color(0xFF4CAF50) : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                color: isOpen ? Color(0xFF4CAF50) : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "· $closingTime",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onDetailsPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4DB6AC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Détails",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onNavigationPressed,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation,
                  size: 20,
                  color: Color(0xFF4DB6AC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _BottomItem(icon: Icons.home, label: "Home", active: true),
            _BottomItem(
              icon: Icons.local_pharmacy_outlined,
              label: "Pharmacies",
            ),
            _BottomItem(icon: Icons.history, label: "Historique"),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? Colors.teal : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.teal : Colors.grey,
          ),
        ),
      ],
    );
  }
}
