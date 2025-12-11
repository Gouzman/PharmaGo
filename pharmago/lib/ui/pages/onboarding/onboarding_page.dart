import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/local_storage.dart';
import '../../widgets/segmented_progress_bar.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Current step (1-based)
  int _currentStep = 1;

  // Form data
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCity;
  String? _selectedCommune;
  String? _selectedNeighborhood;

  // Calcul dynamique du nombre total d'étapes
  int get _totalSteps {
    if (_selectedCity == 'Abidjan') {
      return 4; // Nom + Ville + Commune + Quartier
    }
    return 3; // Nom + Ville + Quartier
  }

  // Villes de Côte d'Ivoire
  final List<String> _cities = ['Abidjan', 'Yamoussoukro', 'Korhogo', 'Bouaké'];

  // Communes/Quartiers par ville
  final Map<String, List<String>> _communesByCity = {
    'Abidjan': [
      'Cocody',
      'Yopougon',
      'Abobo',
      'Marcory',
      'Koumassi',
      'Treichville',
      'Plateau',
      'Port-Bouët',
      'Attécoubé',
      'Adjamé',
      'Bingerville',
      'Songon',
    ],
    'Yamoussoukro': [
      '220 Logements',
      'Habitat',
      'N\'Gattakro',
      'Assabou',
      'Kossou',
      'Kokrenou',
      'Morofé',
      'Millionnaire',
      'Lycée Scientifique',
      'Dioulakro',
      'Akpkessou',
      'Sopim',
      'Belle-Ville',
      'Habitat Extension',
    ],
    'Korhogo': [
      'Haoussabougou',
      'Koko',
      'Soba',
      'Petit Paris',
      'Kombolokoura',
      'Sinistré',
      'Tioro',
      'Allokoko',
      'Mission',
      'Kapélé',
      'Logoualé',
      'Dar-es-Salaam',
      'Dioulabougou',
      'Quartier Commerce',
    ],
    'Bouaké': [
      'Air France 1',
      'Air France 2',
      'Air France 3',
      'Kennedy',
      'Dar-es-Salaam',
      'Koko',
      'Broukro',
      'Belleville',
      'N\'Gattakro',
      'Sokoura',
      'Ahougnassou',
      'Nimbo',
      'Kouakoukro',
      'Odiennekourani',
      'Gonfreville',
      'Zone Industrielle',
      'Commerce',
      'Tchèlèkro',
      'SBB',
    ],
  };

  // Sous-quartiers par commune (Abidjan uniquement)
  final Map<String, List<String>> _neighborhoodsByCommune = {
    'Cocody': [
      'Angré',
      'Riviera I',
      'Riviera II',
      'Riviera III',
      'Riviera Bonoumin',
      'Riviera Palmeraie',
      'Akouédo',
      '7e Tranche',
      '8e Tranche',
      '9e Tranche',
      'M\'Pouto',
      'II Plateaux',
      'II Plateaux Vallon',
      'II Plateaux Sideci',
      'Danga',
      'Blockhaus',
      'St Jean',
      'Bonoumin',
      'Lycée Technique',
      'Cocody Centre',
      'Attoban',
    ],
    'Yopougon': [
      'Sogefhia',
      'Maroc',
      'Toits Rouges',
      'Sicogi',
      'Andokoi',
      'Niangon Nord',
      'Niangon Sud',
      'Niangon Attié',
      'Académie',
      'Gesco',
      'Ananeraie',
      'Selmer',
      'Wassakara',
      'Banco',
      'Kouté',
      'Nouveau Quartier',
      'Siporex',
      'Port-Bouët II',
    ],
    'Abobo': [
      'Abobo Baoulé',
      'Abobo Clouetcha',
      'Abobo Gare',
      'Belleville',
      'PK18',
      'N\'Dotré',
      'Sogefiha',
      'Samaké',
      'Anonkoua-Kouté',
      'Avocatier',
      'Agbekoi',
      'Dokui',
      'Sagbé',
      'M\'Pouto Abobo',
      'Derrière Rails',
    ],
    'Marcory': [
      'Zone 4',
      'Bietry',
      'Anoumabo',
      'Hibiscus',
      'Résidentiel',
      'Marcory Centre',
      'SICOGI',
    ],
    'Koumassi': [
      'Remblais',
      'Grand Campement',
      'Prodomo',
      'Zinsou',
      'Divo',
      'SICOGI',
      'Koumassi Centre',
      'Terminus 47',
    ],
    'Treichville': [
      'Avenue 8',
      'Arrondissement',
      'Belleville',
      'Rue 12',
      'Arras',
      'Zone portuaire',
    ],
    'Plateau': [
      'Plateau Nord',
      'Plateau Sud',
      'Cité Administrative',
      'Indénié',
      'Banque',
      'Commerce',
    ],
    'Port-Bouët': [
      'Vridi',
      'Gonzagueville',
      'Port-Bouët Plage',
      'Adjouffou',
      'Abattoir',
      'Aeroport',
    ],
    'Attécoubé': ['Mossikro', 'Abobo Doumé', 'Locodjro', 'Attécoubé Centre'],
    'Adjamé': [
      'Williamsville',
      '220 Logements',
      'Adjamé Liberté',
      'Bracodi',
      'Indénié',
      'Bromakoté',
    ],
    'Bingerville': [
      'Akouai Santai',
      'Eloka',
      'M\'Badon',
      'Bingerville Centre',
      'Riviera Manga',
      'Blanchon',
    ],
    'Songon': [
      'Songon Kassemblé',
      'Songon Dagbé',
      'Songon M\'Braté',
      'Songon Agban',
      'Songon Té',
      'Songon Aboisso',
    ],
  };

  List<String> get _availableCommunes {
    if (_selectedCity == null) return [];
    return _communesByCity[_selectedCity!] ?? [];
  }

  List<String> get _availableNeighborhoods {
    if (_selectedCity != 'Abidjan' || _selectedCommune == null) return [];
    return _neighborhoodsByCommune[_selectedCommune!] ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Validates current step before moving forward
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        if (_nameController.text.trim().isEmpty) {
          _showErrorDialog('Veuillez entrer votre nom complet.');
          return false;
        }
        return true;
      case 2:
        if (_selectedCity == null) {
          _showErrorDialog('Veuillez sélectionner une ville.');
          return false;
        }
        return true;
      case 3:
        // Pour Abidjan: étape commune
        if (_selectedCity == 'Abidjan') {
          if (_selectedCommune == null) {
            _showErrorDialog('Veuillez sélectionner une commune.');
            return false;
          }
          return true;
        } else {
          // Pour autres villes: étape quartier (dernière étape)
          if (_selectedCommune == null) {
            _showErrorDialog('Veuillez sélectionner un quartier.');
            return false;
          }
          return true;
        }
      case 4:
        // Pour Abidjan uniquement: étape quartier
        if (_selectedNeighborhood == null) {
          _showErrorDialog('Veuillez sélectionner un quartier.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  /// Shows error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handles next button press
  void _handleNext() async {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps) {
        setState(() {
          _currentStep++;
        });
      } else {
        // Form completed - save data and navigate
        final district = _selectedCity == 'Abidjan'
            ? _selectedNeighborhood ?? ''
            : _selectedCommune ?? '';

        await LocalStorage.saveUserData(
          name: _nameController.text,
          country: 'Côte d\'Ivoire',
          city: _selectedCity ?? '',
          district: district,
        );
        if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  /// Handles back button press
  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFB5E6D1), // vert menthe
              Color(0xFFFBFCFD), // blanc cassé
              Color(0xFF9BB1C0), // bleu grisé
            ],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar at top
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SegmentedProgressBar(
                      totalSteps: _totalSteps,
                      currentStep: _currentStep,
                    ),
                  ),

                  // Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildStepContent(),
                    ),
                  ),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Back button
                        if (_currentStep > 1)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleBack,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF1A5276),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Retour',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A5276),
                                ),
                              ),
                            ),
                          ),

                        if (_currentStep > 1) const SizedBox(width: 16),

                        // Next/Finish button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A5276),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep < _totalSteps
                                  ? 'Suivant'
                                  : 'Terminer',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds content for current step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1(); // Nom
      case 2:
        return _buildStep2(); // Ville
      case 3:
        if (_selectedCity == 'Abidjan') {
          return _buildStep3Commune(); // Commune pour Abidjan
        } else {
          return _buildStep3Quartier(); // Quartier pour autres villes
        }
      case 4:
        return _buildStep4Quartier(); // Quartier pour Abidjan uniquement
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 1: Full Name
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 01',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5276),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Quel est votre nom complet ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Color(0xFF1A5276)),
          decoration: InputDecoration(
            hintText: 'Entrez votre nom complet',
            hintStyle: const TextStyle(color: Color(0xFF7B8D9B)),
            helperText: 'Veuillez entrer votre nom complet.',
            helperStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A5276),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A5276)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7B8D9B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A5276), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 2: Select City
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 02',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5276),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sélectionnez votre ville',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),
        ..._cities.map((city) {
          return _buildRadioOption(
            value: city,
            groupValue: _selectedCity,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _selectedCommune = null;
                _selectedNeighborhood = null;
              });
            },
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 3: Select Commune (Abidjan uniquement)
  Widget _buildStep3Commune() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 03',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5276),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sélectionnez votre commune',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),

        ..._availableCommunes.map((commune) {
          return _buildRadioOption(
            value: commune,
            groupValue: _selectedCommune,
            onChanged: (value) {
              setState(() {
                _selectedCommune = value;
                _selectedNeighborhood = null;
              });
            },
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 3: Select Quartier (autres villes que Abidjan)
  Widget _buildStep3Quartier() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 03',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5276),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sélectionnez votre quartier',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),

        ..._availableCommunes.map((quartier) {
          return _buildRadioOption(
            value: quartier,
            groupValue: _selectedCommune,
            onChanged: (value) {
              setState(() {
                _selectedCommune = value;
              });
            },
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 4: Select Quartier (Abidjan uniquement)
  Widget _buildStep4Quartier() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 04',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5276),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sélectionnez votre quartier',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),

        ..._availableNeighborhoods.map((neighborhood) {
          return _buildRadioOption(
            value: neighborhood,
            groupValue: _selectedNeighborhood,
            onChanged: (value) {
              setState(() {
                _selectedNeighborhood = value;
              });
            },
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds a radio option with optional leading widget
  Widget _buildRadioOption({
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
    Widget? leading,
  }) {
    final isSelected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF1A5276) : const Color(0xFF7B8D9B),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? const Color(0xFF1A5276).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: const Color(0xFF1A5276),
                ),
              ),
            ),
          ],
        ),
        activeColor: const Color(0xFF1A5276),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
