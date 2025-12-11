# Guide d'utilisation : Personnage PNG marchant sur la route

## 📋 Résumé

Vous avez maintenant **2 options** pour votre barre de progression animée :

### Option 1 : `JourneyProgressBar` (Actuelle)
- ✅ Déjà intégrée dans votre Splash Screen
- 🎨 Utilise un personnage dessiné (stick figure)
- ⚡ Animations de marche avec jambes qui bougent
- 🎯 Bobbing et rotation déjà implémentés

### Option 2 : `WalkingPersonRoadProgressBar` (Nouvelle - avec PNG)
- 🖼️ Utilise votre image PNG personnalisée
- 🎭 Animations avancées (bobbing, rotation, direction)
- 📦 Prête à l'emploi une fois l'image ajoutée

---

## 🚀 Comment utiliser le widget avec votre image PNG

### Étape 1 : Ajoutez votre image

Placez votre image PNG du personnage marchant dans :
```
assets/images/walking_person.png
```

### Étape 2 : Mettez à jour pubspec.yaml

Assurez-vous que le dossier images est déclaré :
```yaml
flutter:
  assets:
    - assets/logo/
    - assets/images/
    - assets/splash/
```

### Étape 3 : Remplacez le widget dans splash_page.dart

**Remplacez** :
```dart
import '../../widgets/journey_progress_bar.dart';

// ...

const JourneyProgressBar(duration: Duration(seconds: 10)),
```

**Par** :
```dart
import '../../widgets/walking_person_road_progress_bar.dart';

// ...

const WalkingPersonRoadProgressBar(
  duration: Duration(seconds: 10),
  imagePath: 'assets/images/walking_person.png',
),
```

---

## 📝 Code complet du Splash Screen (Option PNG)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/local_storage.dart';
import '../../widgets/walking_person_road_progress_bar.dart'; // ← Nouveau import

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
    await Future.delayed(const Duration(seconds: 10));

    final done = await LocalStorage.hasUserData();

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset('assets/logo/splash.png', width: 150, height: 150),
              const SizedBox(height: 16),

              // Texte "PharmaGo"
              const Text(
                "PharmaGo",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5276),
                ),
              ),

              const SizedBox(height: 40),

              // ✨ Barre de progression avec PNG ✨
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
```

---

## 🎨 Fonctionnalités de l'animation PNG

### ✅ Implémenté automatiquement :

1. **Suivi de chemin courbe** 🛣️
   - Le personnage suit exactement la courbe bezier

2. **Effet de marche réaliste** 🚶
   - Bobbing vertical (monte et descend)
   - Rotation légère (bascule gauche/droite)
   
3. **Orientation dynamique** 🧭
   - Le personnage s'oriente dans la direction du chemin

4. **Animations fluides** ✨
   - CurvedAnimation avec easeInOut
   - 30 FPS pour le bobbing
   - 25 FPS pour la rotation

5. **Fallback intelligent** 🔄
   - Si l'image ne charge pas, affiche un personnage dessiné

---

## 🎯 Paramètres personnalisables

```dart
WalkingPersonRoadProgressBar(
  duration: Duration(seconds: 10),        // Durée totale
  imagePath: 'assets/images/person.png',  // Chemin de l'image
  onComplete: () {                         // Callback optionnel
    print('Animation terminée !');
  },
)
```

---

## 📐 Ajustement de la taille de l'image

Si votre image PNG est trop grande ou trop petite, modifiez cette ligne dans `walking_person_road_progress_bar.dart` :

```dart
final imageSize = 50.0; // ← Changez cette valeur (ligne ~330)
```

Valeurs recommandées :
- Petit : `40.0`
- Moyen : `50.0` (par défaut)
- Grand : `60.0` ou `70.0`

---

## 🐛 Dépannage

### L'image ne s'affiche pas ?

1. Vérifiez que le fichier existe : `assets/images/walking_person.png`
2. Vérifiez `pubspec.yaml` : le dossier `assets/images/` est déclaré
3. Relancez : `flutter clean && flutter pub get`
4. Le fallback (stick figure) s'affichera automatiquement en attendant

### L'animation est saccadée ?

- Normal sur simulateur, testez sur un vrai appareil
- Réduisez la fréquence du bobbing (changez `* 30` à `* 20`)

---

## 🎁 Bonus : Tester rapidement

Pour tester sans ajouter d'image PNG immédiatement, le widget affichera automatiquement un personnage dessiné animé comme fallback !

---

**Créé avec ❤️ pour PharmaGo**
