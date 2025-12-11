import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmaGo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_pharmacy, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Bienvenue sur PharmaGo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implémenter la recherche de pharmacies
              },
              icon: const Icon(Icons.search),
              label: const Text('Trouver une pharmacie'),
            ),
          ],
        ),
      ),
    );
  }
}
