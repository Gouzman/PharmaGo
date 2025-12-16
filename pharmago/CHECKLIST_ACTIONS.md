# ✅ CHECKLIST ACTIONS À FAIRE

## 📋 Actions Manuelles Requises

### ⚡ CONFIGURATION (5 minutes)

#### 1. Configurer Supabase

**a) Créer un projet Supabase**
- [ ] Aller sur https://supabase.com
- [ ] Créer un compte (gratuit)
- [ ] Créer un nouveau projet
- [ ] Noter l'URL du projet
- [ ] Noter la clé anon/public

**b) Configurer le backend**
- [ ] Ouvrir `PharmaGoBackend/appsettings.json`
- [ ] Remplacer `Supabase:Url` par votre URL
- [ ] Remplacer `Supabase:Key` par votre clé

**c) Exécuter le schéma SQL**
- [ ] Aller dans Supabase → SQL Editor
- [ ] Ouvrir le fichier `PharmaGoBackend/supabase_schema_complete.sql`
- [ ] Copier tout le contenu
- [ ] Coller dans l'éditeur SQL
- [ ] Exécuter (bouton RUN)

**d) Créer le bucket Storage**
- [ ] Aller dans Supabase → Storage
- [ ] Cliquer "Create bucket"
- [ ] Nom : `pharmacy_data`
- [ ] Public : ✅ Cocher
- [ ] Créer

---

### 🔧 CODE FLUTTER (5 minutes)

#### 2. Mettre à jour le Router

**Fichier :** `pharmago/lib/router/app_router.dart`

- [ ] Ouvrir le fichier
- [ ] Chercher `import 'pharmacy_detail_page.dart'`
- [ ] Remplacer par `import 'pharmacy_detail_page_osm.dart'`
- [ ] Chercher `PharmacyDetailPage(`
- [ ] Remplacer par `PharmacyDetailPageOSM(`
- [ ] Adapter les paramètres si nécessaire

**Exemple :**
```dart
// Avant
import '../ui/pages/pharmacy/pharmacy_detail_page.dart';

// Après
import '../ui/pages/pharmacy/pharmacy_detail_page_osm.dart';

// Avant
PharmacyDetailPage(
  pharmacyId: pharmacy.id,
  name: pharmacy.name,
  // ...
)

// Après
PharmacyDetailPageOSM(
  pharmacy: pharmacy,
)
```

#### 3. Supprimer les clés Google Maps

**a) Android**

Fichier : `pharmago/android/app/src/main/AndroidManifest.xml`

- [ ] Ouvrir le fichier
- [ ] Chercher `<meta-data android:name="com.google.android.geo.API_KEY"`
- [ ] Supprimer toute la ligne
- [ ] Sauvegarder

**b) iOS**

Fichier : `pharmago/ios/Runner/AppDelegate.swift`

- [ ] Ouvrir le fichier
- [ ] Chercher `GMSServices.provideAPIKey`
- [ ] Supprimer toute la ligne
- [ ] Sauvegarder

#### 4. Configurer l'URL Backend

**Fichier :** `pharmago/lib/services/pharmacy_data_service.dart`

- [ ] Ouvrir le fichier
- [ ] Chercher `static const String? _backendUrl`
- [ ] Changer de `null` vers votre URL backend
- [ ] Changer `_useTestData` de `true` vers `false`

**Exemple :**
```dart
// Pour développement local
static const String? _backendUrl = 'http://localhost:5000';

// Pour production
static const String? _backendUrl = 'https://votre-backend.railway.app';

// Désactiver mode test
static const bool _useTestData = false;
```

---

### 🧪 TESTS (10 minutes)

#### 5. Tester le Backend

- [ ] Ouvrir un terminal
- [ ] `cd PharmaGoBackend`
- [ ] `dotnet run`
- [ ] Vérifier que ça démarre sans erreur
- [ ] Ouvrir http://localhost:5000 dans le navigateur
- [ ] Vérifier Swagger UI s'affiche
- [ ] Tester `/api/pharmacies/latest`
- [ ] Vérifier les logs CRON : `🕐 GuardUpdater démarré`

#### 6. Tester Flutter iOS

- [ ] Ouvrir un terminal
- [ ] `cd pharmago`
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter run -d ios`
- [ ] Vérifier :
  - [ ] La carte OSM s'affiche
  - [ ] Les pharmacies apparaissent
  - [ ] Les permissions GPS sont demandées
  - [ ] Le calcul d'itinéraire fonctionne

#### 7. Tester Flutter Android

- [ ] Ouvrir un terminal
- [ ] `cd pharmago`
- [ ] `flutter run -d android`
- [ ] Vérifier :
  - [ ] La carte OSM s'affiche
  - [ ] Les pharmacies apparaissent
  - [ ] Les permissions GPS sont demandées
  - [ ] Le calcul d'itinéraire fonctionne

---

### 🚀 DÉPLOIEMENT (30 minutes)

#### 8. Déployer le Backend

**Option A : Railway.app (recommandé)**

- [ ] Installer Railway CLI : `npm install -g @railway/cli`
- [ ] `railway login`
- [ ] `cd PharmaGoBackend`
- [ ] `railway init`
- [ ] `railway up`
- [ ] Configurer variables :
  - [ ] `railway variables set Supabase__Url=https://...`
  - [ ] `railway variables set Supabase__Key=...`
- [ ] Noter l'URL publique du backend

**Option B : Render.com**

- [ ] Créer un compte sur https://render.com
- [ ] Nouveau Web Service
- [ ] Connecter le repo GitHub
- [ ] Build Command : `dotnet publish -c Release`
- [ ] Start Command : `dotnet PharmaGoBackend.dll`
- [ ] Ajouter variables d'environnement :
  - [ ] `Supabase__Url`
  - [ ] `Supabase__Key`

**Option C : VPS**

- [ ] Connexion SSH au serveur
- [ ] Installer .NET 8 Runtime
- [ ] `dotnet publish -c Release -o /var/www/pharmago`
- [ ] Créer service systemd
- [ ] Démarrer le service

#### 9. Mettre à jour l'URL Backend dans Flutter

- [ ] Ouvrir `pharmago/lib/services/pharmacy_data_service.dart`
- [ ] Changer `_backendUrl` vers l'URL de production
- [ ] Rebuild l'app

#### 10. Build Release Flutter

**Android :**
- [ ] `cd pharmago`
- [ ] `flutter build apk --release`
- [ ] Récupérer : `build/app/outputs/flutter-apk/app-release.apk`

**iOS :**
- [ ] `cd pharmago`
- [ ] `flutter build ios --release`
- [ ] Ouvrir Xcode et archiver

---

### 🔍 VÉRIFICATIONS FINALES

#### 11. Vérifier l'Architecture Complète

- [ ] Backend déployé et accessible
- [ ] Swagger UI fonctionne
- [ ] JSON généré et uploadé dans Supabase Storage
- [ ] URL JSON publique accessible
- [ ] App Flutter se connecte au backend
- [ ] Carte OSM s'affiche correctement
- [ ] Itinéraires OSRM calculés
- [ ] Permissions GPS gérées
- [ ] Mode offline fonctionne (cache)

#### 12. Vérifier les CRON

- [ ] GuardUpdater s'exécute à minuit (logs)
- [ ] PharmacyUpdater s'exécute toutes les 6h
- [ ] JSON régénéré automatiquement
- [ ] Pharmacies de garde mises à jour

#### 13. Vérifier la Sécurité

- [ ] Aucune clé Google Maps dans le code
- [ ] `appsettings.json` dans `.gitignore`
- [ ] Clés Supabase sécurisées (anon key uniquement)
- [ ] Bucket Storage PUBLIC (lecture seule)
- [ ] RLS activées sur les tables Supabase

---

## 📊 CHECKLIST COMPLÈTE

### ✅ Automatique (Déjà fait)

- [x] Services Flutter créés (OSRM, Location)
- [x] Widget OSMMap créé
- [x] Page PharmacyDetailOSM créée
- [x] Backend fonctionnel
- [x] CRON configurés
- [x] Schéma SQL créé
- [x] Documentation complète
- [x] Scripts d'installation
- [x] .gitignore configuré

### ⚠️ Manuel (À faire)

**Configuration**
- [ ] Configurer Supabase (5 min)
- [ ] Créer bucket Storage
- [ ] Exécuter schéma SQL

**Code Flutter**
- [ ] Mettre à jour router
- [ ] Supprimer clés Google Maps
- [ ] Configurer URL backend

**Tests**
- [ ] Tester backend
- [ ] Tester Flutter iOS
- [ ] Tester Flutter Android

**Déploiement**
- [ ] Déployer backend
- [ ] Build release

**Vérifications**
- [ ] Architecture complète
- [ ] CRON actifs
- [ ] Sécurité

---

## 🎯 PRIORITÉS

### 🔥 Urgent (Faire en premier)

1. Configurer Supabase
2. Tester backend local
3. Tester Flutter local

### ⚡ Important (Faire ensuite)

4. Mettre à jour router
5. Supprimer clés Google Maps
6. Tester sur iOS/Android

### 📅 Peut attendre

7. Déployer backend
8. Build release
9. Vérifications finales

---

## ⏱️ TEMPS ESTIMÉ

| Tâche | Temps |
|-------|-------|
| Configuration Supabase | 5 min |
| Code Flutter | 5 min |
| Tests | 10 min |
| Déploiement | 30 min |
| Vérifications | 10 min |
| **TOTAL** | **60 min** |

---

## 📞 AIDE

En cas de problème :

1. ✅ Consulter [`MIGRATION_OSM_GUIDE.md`](./MIGRATION_OSM_GUIDE.md) - Section Dépannage
2. ✅ Vérifier les logs : `flutter logs` / `dotnet run`
3. ✅ Tester manuellement les API (curl)
4. ✅ Consulter [`COMMANDES_UTILES.md`](./COMMANDES_UTILES.md)

---

**✅ Bonne chance ! Suivez cette checklist étape par étape.**

*Dernière mise à jour : 14 décembre 2024*
