# 🎯 GUIDE DE DÉMARRAGE RAPIDE - PharmaGo

## ⚡ Démarrer l'application en 3 étapes

### Étape 1️⃣ : Configurer le Backend (Optionnel pour tester l'UI)

L'application Flutter peut fonctionner **sans backend** grâce au cache local. Mais pour récupérer de vraies données :

#### Option A : Backend local (.NET 8)
```bash
cd PharmaGoBackend/src
dotnet restore
dotnet build
dotnet run --project API
```

Créez `appsettings.json` avec vos credentials Supabase :
```json
{
  "Supabase": {
    "Url": "https://VOTRE_PROJET.supabase.co",
    "Key": "votre_anon_key"
  }
}
```

#### Option B : Utiliser des données de test
L'application affichera "Aucune pharmacie disponible" mais l'UI est fonctionnelle.

---

### Étape 2️⃣ : Lancer l'application Flutter

```bash
cd pharmago
flutter pub get
flutter run
```

✅ L'application va :
1. Demander la permission GPS
2. Récupérer votre position
3. Charger les pharmacies (depuis backend ou cache)
4. Afficher les cartes triées par distance

---

### Étape 3️⃣ : Voir les changements ! 🎉

#### Ce qui a changé sur l'interface :

**AVANT (données hardcodées)** :
```dart
_PharmacyCard(
  name: "Pharmacie St Gabriel",
  distance: "0.8 km",  // ❌ Statique
  ...
),
```

**MAINTENANT (données dynamiques)** :
```dart
Consumer<PharmacyProvider>(
  builder: (context, provider, _) {
    return ListView(
      children: provider.nearbyPharmacies.map((pharmacy) {
        // ✅ Distance calculée en temps réel
        final distance = pharmacy.distanceFrom(userLat, userLng);
        
        return _PharmacyCard(
          name: pharmacy.name,           // ✅ Depuis backend
          distance: '$distance km',      // ✅ Calculé dynamiquement
          isGuard: pharmacy.isGuard,     // ✅ Badge "GARDE" si vrai
          ...
        );
      }).toList(),
    );
  },
),
```

#### Nouveautés visibles :

1. **Bouton refresh** (⟳) en haut à droite
   - Cliquez pour synchroniser avec le backend
   - Affiche un loader pendant le chargement
   - SnackBar de confirmation après sync

2. **Nombre de pharmacies** dynamique
   - Avant : "0 - 5km" (statique)
   - Maintenant : "12 pharmacies · 0 - 5km" (dynamique)

3. **Badge "DE GARDE"** 🟠
   - Apparaît sur les pharmacies de garde
   - Bordure orange + icône spéciale
   - Badge orange avec "GARDE"

4. **États de chargement**
   - **Loading** : Loader circulaire + "Chargement des pharmacies..."
   - **Empty** : "Aucune pharmacie disponible" + bouton "Réessayer"
   - **Data** : Liste des pharmacies

5. **Distance en temps réel**
   - Calculée depuis votre position GPS
   - Mise à jour automatiquement

---

## 🔍 Vérifier que ça fonctionne

### Test 1 : Chargement initial
1. Lancez l'app
2. ✅ Vous voyez un loader "Chargement des pharmacies..."
3. ✅ Les cartes apparaissent (ou message "Aucune pharmacie" si pas de backend)

### Test 2 : Bouton refresh
1. Cliquez sur l'icône ⟳ en haut à droite
2. ✅ L'icône devient un loader qui tourne
3. ✅ Message "✅ Pharmacies mises à jour" s'affiche

### Test 3 : Badge DE GARDE
1. Si une pharmacie est de garde dans vos données backend
2. ✅ Badge orange "GARDE" visible
3. ✅ Bordure orange autour de la carte
4. ✅ Icône `medical_services` au lieu de `local_pharmacy`

### Test 4 : Distance calculée
1. Donnez la permission GPS
2. ✅ Les distances affichées correspondent à votre position réelle
3. ✅ Les pharmacies sont triées de la plus proche à la plus éloignée

---

## 📊 Où sont les données ?

### Structure du cache local
```
SharedPreferences
├── pharmacy_data_version = "638123456789012345"  // Timestamp
├── pharmacy_data_json = "[{...}, {...}]"          // Liste des pharmacies
└── pharmacy_data_timestamp = "2024-01-15T..."    // Date de dernière sync
```

### Vérifier le cache (optionnel)
```dart
// Dans Dart DevTools Console
final prefs = await SharedPreferences.getInstance();
print(prefs.getInt('pharmacy_data_version'));
```

---

## 🎨 Personnalisation

### Modifier le rayon de recherche
Par défaut : 5 km

```dart
// pharmago/lib/providers/pharmacy_provider.dart
List<Pharmacy> _getNearbyPharmacies() {
  return _pharmacies
      .where((p) => p.distanceFrom(...) <= 5.0)  // ← Changez ici
      .toList();
}
```

### Changer l'URL du backend
```dart
// pharmago/lib/services/pharmacy_data_service.dart
static const String baseUrl = 'http://localhost:5000';  // ← Votre URL
```

### Modifier la couleur du badge DE GARDE
```dart
// pharmago/lib/ui/pages/home/home_page.dart
Container(
  decoration: BoxDecoration(
    color: const Color(0xFFFF6F00),  // ← Changez ici
  ),
  ...
)
```

---

## 🐛 Problèmes courants

### "Aucune pharmacie disponible"
**Cause** : Le backend n'est pas lancé ou ne retourne pas de données

**Solution** :
1. Vérifiez que le backend tourne : `dotnet run --project API`
2. Testez l'API : `curl http://localhost:5000/api/pharmacies/latest`
3. Vérifiez les logs Flutter : cherchez "❌" dans la console

### "Position GPS indisponible"
**Cause** : Permissions refusées

**Solution** :
1. Allez dans les paramètres de l'app
2. Activez "Localisation"
3. Redémarrez l'app

### Le bouton refresh ne fait rien
**Cause** : URL du backend incorrecte

**Solution** :
1. Ouvrez `lib/services/pharmacy_data_service.dart`
2. Vérifiez `baseUrl`
3. Relancez l'app

---

## 📱 Tester sur un appareil physique

### Android
```bash
flutter run -d <device_id>
```

### iOS
```bash
flutter run -d <device_id>
```

### Permissions requises
- ✅ Localisation (obligatoire)
- ✅ Internet (obligatoire)
- ✅ Stockage (pour le cache - automatique)

---

## 🎉 Félicitations !

Vous avez maintenant une application **complètement intégrée** avec :

✅ Backend .NET 8 professionnel
✅ Base de données Supabase
✅ Système de CRON automatique
✅ API REST sécurisée
✅ Frontend Flutter moderne
✅ Cache offline intelligent
✅ Synchronisation en temps réel
✅ UI/UX optimisée

**Les données hardcodées ont été remplacées par des vraies données du backend ! 🚀**

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Consultez `INTEGRATION_GUIDE.md` pour la documentation complète
2. Vérifiez `CHANGELOG_INTEGRATION.md` pour voir tous les changements
3. Consultez les logs dans la console Flutter (cherchez 🔍 les emoji)

**Bon développement ! 💪**
