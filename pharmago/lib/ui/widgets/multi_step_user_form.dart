import 'package:flutter/material.dart';
import '../widgets/segmented_progress_bar.dart';

/// Multi-step user information form with modern card design
class MultiStepUserForm extends StatefulWidget {
  const MultiStepUserForm({super.key});

  @override
  State<MultiStepUserForm> createState() => _MultiStepUserFormState();
}

class _MultiStepUserFormState extends State<MultiStepUserForm> {
  // Current step (1-based)
  int _currentStep = 1;
  final int _totalSteps = 4;

  // Form data
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedNeighborhood;

  // Mock data for countries with flags
  final List<Map<String, String>> _countries = [
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Maroc', 'flag': '🇲🇦'},
    {'name': 'Algérie', 'flag': '🇩🇿'},
    {'name': 'Tunisie', 'flag': '🇹🇳'},
    {'name': 'Belgique', 'flag': '🇧🇪'},
    {'name': 'Suisse', 'flag': '🇨🇭'},
    {'name': 'Canada', 'flag': '🇨🇦'},
  ];

  // Mock data for cities
  final List<String> _cities = [
    'Paris',
    'Casablanca',
    'Alger',
    'Tunis',
    'Bruxelles',
    'Genève',
    'Montréal',
    'Lyon',
    'Rabat',
    'Oran',
  ];

  // Mock data for neighborhoods
  final List<String> _neighborhoods = [
    'Centre-ville',
    'Maarif',
    'Gauthier',
    'Anfa',
    'Bourgogne',
    'Hay Hassani',
    'Ain Diab',
    'Sidi Moumen',
    'Derb Sultan',
    'Racine',
  ];

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
        if (_selectedCountry == null) {
          _showErrorDialog('Veuillez sélectionner un pays.');
          return false;
        }
        return true;
      case 3:
        if (_selectedCity == null) {
          _showErrorDialog('Veuillez sélectionner une ville.');
          return false;
        }
        return true;
      case 4:
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
  void _handleNext() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps) {
        setState(() {
          _currentStep++;
        });
      } else {
        // Form completed
        _showCompletionDialog();
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

  /// Shows completion dialog
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Formulaire complété'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${_nameController.text}'),
            Text('Pays: $_selectedCountry'),
            Text('Ville: $_selectedCity'),
            Text('Quartier: $_selectedNeighborhood'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF1A5276)),
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
                      _currentStep < _totalSteps ? 'Suivant' : 'Terminer',
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
    );
  }

  /// Builds content for current step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
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
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'What is your full name?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Entrez votre nom complet',
            helperText: 'Please enter your complete name.',
            helperStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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

  /// Step 2: Select Country
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 02',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select your country',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),
        ..._countries.map((country) {
          return _buildRadioOption(
            value: country['name']!,
            groupValue: _selectedCountry,
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
            },
            leading: Text(
              country['flag']!,
              style: const TextStyle(fontSize: 28),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 3: Select City
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 03',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select your city',
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
              });
            },
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 4: Select Neighborhood
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUESTION 04',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select your neighborhood (Quartier)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5276),
          ),
        ),
        const SizedBox(height: 24),
        ..._neighborhoods.map((neighborhood) {
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
          color: isSelected ? const Color(0xFF1A5276) : const Color(0xFFE0E0E0),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
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
                  color: isSelected
                      ? const Color(0xFF1A5276)
                      : const Color(0xFF424242),
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
