import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _AdCarousel(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pharmacie à proximité",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "0 - 5km",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Voir tout",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Section scrollable
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PharmacyCard(
                          name: "Pharmacie St Gabriel",
                          subtitle: "92Q5+528, Bd des Martyrs · 07 09 02 7356",
                          address: "Bd des Martyrs",
                          status: "Ouvert",
                          closingTime: "Ferme à 20:00",
                          distance: "0.8 km",
                          isOpen: true,
                          onTap: () {},
                          onDetailsPressed: () {
                            context.push(
                              '/pharmacy/1?name=Pharmacie St Gabriel&address=92Q5+528, Bd des Martyrs&isOpen=true&distance=0.8&lat=5.345317&lng=-4.024429',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _PharmacyCard(
                          name: "Pharmacie de la Riviera",
                          subtitle: "Riviera Palmeraie",
                          address: "Avenue 18, Riviera · 27 21 23 45 67",
                          status: "Ouvert",
                          closingTime: "Ferme à 22:00",
                          distance: "1.5 km",
                          isOpen: true,
                          onTap: () {},
                          onDetailsPressed: () {
                            context.push(
                              '/pharmacy/2?name=Pharmacie de la Riviera&address=Avenue 18, Riviera&isOpen=true&distance=1.5&lat=5.355317&lng=-4.014429',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _PharmacyCard(
                          name: "Pharmacie Principale d'Aboboté",
                          subtitle: "Pharmacie Principale d'Aboboté",
                          address:
                              "CX89+H6V Pharmacie, Autoroute d'Abobo · 42527779",
                          status: "Ouvert",
                          closingTime: "Ferme à 20:00",
                          distance: "2.3 km",
                          isOpen: true,
                          onTap: () {},
                          onDetailsPressed: () {
                            context.push(
                              '/pharmacy/3?name=Pharmacie Principale d\'Aboboté&address=CX89+H6V Pharmacie, Autoroute d\'Abobo&isOpen=true&distance=2.3&lat=5.365317&lng=-4.034429',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _PharmacyCard(
                          name: "Pharmacie du Plateau",
                          subtitle: "Plateau Centre",
                          address: "Rue du Commerce · 27 20 21 22 23",
                          status: "Ouvert",
                          closingTime: "Ferme à 21:00",
                          distance: "3.7 km",
                          isOpen: true,
                          onTap: () {},
                          onDetailsPressed: () {
                            context.push(
                              '/pharmacy/4?name=Pharmacie du Plateau&address=Rue du Commerce, Plateau&isOpen=true&distance=3.7&lat=5.335317&lng=-4.004429',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _PharmacyCard(
                          name: "Pharmacie Yopougon",
                          subtitle: "Yopougon Sideci",
                          address: "Rue Princesse, Yopougon · 05 06 07 08 09",
                          status: "Ouvert",
                          closingTime: "Ferme à 19:00",
                          distance: "4.8 km",
                          isOpen: true,
                          onTap: () {},
                          onDetailsPressed: () {
                            context.push(
                              '/pharmacy/5?name=Pharmacie Yopougon&address=Rue Princesse, Yopougon&isOpen=true&distance=4.8&lat=5.325317&lng=-4.044429',
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
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
  final VoidCallback onTap;
  final VoidCallback onDetailsPressed;

  const _PharmacyCard({
    required this.name,
    required this.subtitle,
    required this.address,
    required this.status,
    required this.closingTime,
    required this.distance,
    required this.isOpen,
    required this.onTap,
    required this.onDetailsPressed,
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
                color: Color(0xFF2D5F4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_pharmacy,
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
            Container(
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
