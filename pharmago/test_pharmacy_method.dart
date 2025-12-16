import 'package:pharmago/models/pharmacy.dart';

void main() {
  print('Test de la méthode formatDistanceFrom...');
  
  final pharmacy = Pharmacy(
    id: 'test',
    name: 'Test Pharmacy',
    lat: 48.8566,
    lng: 2.3522,
    address: 'Test Address',
    commune: 'Paris',
    quartier: 'Test',
    phone: '0123456789',
    assurances: [],
    isGuard: false,
    updatedAt: DateTime.now(),
  );

  // Test de formatDistanceFrom
  final formatted = pharmacy.formatDistanceFrom(48.8584, 2.2945);
  print('Distance formatée: $formatted');
  
  // Test de distanceFrom
  final distance = pharmacy.distanceFrom(48.8584, 2.2945);
  print('Distance en km: $distance');
  
  print('✅ Tests réussis!');
}
