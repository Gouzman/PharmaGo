import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyDetailPage extends StatelessWidget {
  final String pharmacyId;

  const PharmacyDetailPage({super.key, required this.pharmacyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la pharmacie'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pharmacie #$pharmacyId',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Adresse'),
              subtitle: Text('123 Rue Example, Paris'),
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('Téléphone'),
              subtitle: Text('+33 1 23 45 67 89'),
            ),
            const ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Horaires'),
              subtitle: Text('Lun-Ven: 9h-19h, Sam: 9h-13h'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/gps/$pharmacyId');
                },
                icon: const Icon(Icons.directions),
                label: const Text('Obtenir l\'itinéraire'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
