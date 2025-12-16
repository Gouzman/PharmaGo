# ⚡ PHARMAGO - COMMANDES UTILES

## 🚀 INSTALLATION

### Installation Complète

```bash
# Exécuter le script d'installation
./install.sh
```

### Installation Manuelle

```bash
# Flutter
cd pharmago
flutter clean
flutter pub get

# Backend .NET
cd PharmaGoBackend
dotnet restore
dotnet build
```

---

## 🏃‍♂️ LANCER L'APPLICATION

### Backend

```bash
cd PharmaGoBackend

# Mode développement
dotnet run

# Mode watch (auto-reload)
dotnet watch run

# Mode production
dotnet run --environment Production
```

**URL Backend** :
- Swagger UI : http://localhost:5000
- API : http://localhost:5000/api/pharmacies/latest

### Flutter

```bash
cd pharmago

# Lister les devices
flutter devices

# Lancer sur iOS
flutter run -d ios

# Lancer sur Android
flutter run -d android

# Lancer sur Chrome (web)
flutter run -d chrome

# Mode release
flutter run --release
```

---

## 🧪 TESTS

### Flutter

```bash
cd pharmago

# Tous les tests
flutter test

# Tests avec coverage
flutter test --coverage

# Analyse statique
flutter analyze

# Formater le code
flutter format lib/
```

### Backend

```bash
cd PharmaGoBackend

# Tous les tests
dotnet test

# Tests avec coverage
dotnet test /p:CollectCoverage=true
```

---

## 🔍 VÉRIFICATIONS

### Vérifier les dépendances

```bash
# Flutter
cd pharmago
flutter pub outdated
flutter pub upgrade

# .NET
cd PharmaGoBackend
dotnet list package --outdated
```

### Vérifier les logs

```bash
# Backend
cd PharmaGoBackend
dotnet run | grep "✅\|❌\|🔄"

# Flutter
cd pharmago
flutter logs | grep "📦\|✅\|❌"
```

### Tester les API manuellement

```bash
# Backend local
curl http://localhost:5000/api/pharmacies/latest

# OSRM (calcul itinéraire Abidjan)
curl "https://router.project-osrm.org/route/v1/driving/-4.024429,5.345317;-4.014429,5.355317?geometries=geojson"

# Vérifier JSON Supabase (après upload)
curl https://VOTRE-PROJET.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json
```

---

## 🛠️ DÉVELOPPEMENT

### Créer un nouveau service Flutter

```bash
cd pharmago/lib/services
touch mon_nouveau_service.dart
```

### Créer un nouveau widget Flutter

```bash
cd pharmago/lib/ui/widgets
touch mon_nouveau_widget.dart
```

### Créer un nouveau Controller .NET

```bash
cd PharmaGoBackend/src/API/Controllers
touch MonNouveauController.cs
```

### Générer les modèles Dart (si json_serializable)

```bash
cd pharmago
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📦 BUILD & DÉPLOIEMENT

### Flutter - Build APK (Android)

```bash
cd pharmago

# Debug
flutter build apk --debug

# Release
flutter build apk --release

# Split par ABI (optimisé)
flutter build apk --split-per-abi
```

**Fichier généré** : `build/app/outputs/flutter-apk/app-release.apk`

### Flutter - Build iOS

```bash
cd pharmago

# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

### Flutter - Build Web

```bash
cd pharmago

flutter build web --release
```

**Fichier généré** : `build/web/`

### Backend - Publier .NET

```bash
cd PharmaGoBackend

# Publier pour Linux
dotnet publish -c Release -r linux-x64 --self-contained false -o ./publish

# Publier pour Windows
dotnet publish -c Release -r win-x64 --self-contained false -o ./publish

# Publier pour macOS
dotnet publish -c Release -r osx-x64 --self-contained false -o ./publish
```

---

## 🚢 DÉPLOIEMENT

### Railway.app (Backend)

```bash
# Installer Railway CLI
npm install -g @railway/cli

# Se connecter
railway login

# Initialiser
railway init

# Déployer
railway up

# Configurer variables
railway variables set Supabase__Url=https://...
railway variables set Supabase__Key=...
```

### Render.com (Backend)

1. Créer un nouveau Web Service
2. Connecter le repo GitHub
3. Build Command : `dotnet publish -c Release`
4. Start Command : `dotnet PharmaGoBackend.dll`
5. Variables d'environnement :
   - `Supabase__Url`
   - `Supabase__Key`

### Vercel/Netlify (Frontend Web)

```bash
cd pharmago

# Build
flutter build web --release

# Déployer sur Vercel
vercel --prod

# Ou Netlify
netlify deploy --prod --dir=build/web
```

---

## 🗄️ SUPABASE

### Exécuter le schéma SQL

```bash
# Copier le fichier
cat PharmaGoBackend/supabase_schema_complete.sql

# Coller dans Supabase → SQL Editor → Exécuter
```

### Créer le bucket Storage

```bash
# Via UI Supabase :
# 1. Storage → Create bucket
# 2. Nom : pharmacy_data
# 3. Public : ✅
```

### Vérifier les données

```sql
-- Supabase → SQL Editor

-- Compter les pharmacies
SELECT COUNT(*) FROM pharmacies;

-- Pharmacies de garde aujourd'hui
SELECT * FROM pharmacies WHERE is_guard = true;

-- Dernière mise à jour
SELECT MAX(updated_at) FROM pharmacies;
```

---

## 🔧 MAINTENANCE

### Nettoyer les caches

```bash
# Flutter
cd pharmago
flutter clean
rm -rf .dart_tool
rm -rf build

# .NET
cd PharmaGoBackend
dotnet clean
rm -rf bin obj
```

### Mettre à jour les dépendances

```bash
# Flutter
cd pharmago
flutter pub upgrade

# .NET
cd PharmaGoBackend
dotnet restore
```

### Vérifier la santé du projet

```bash
# Flutter
cd pharmago
flutter doctor -v

# .NET
cd PharmaGoBackend
dotnet --info
```

---

## 🐛 DÉPANNAGE

### Flutter : Problème de permissions iOS

```bash
cd pharmago/ios
pod install
pod update
```

### Flutter : Problème Android

```bash
cd pharmago/android
./gradlew clean
./gradlew build
```

### Backend : Erreur Supabase

```bash
# Vérifier la configuration
cat PharmaGoBackend/appsettings.json

# Tester la connexion
curl -I https://VOTRE-PROJET.supabase.co
```

### Réinitialiser complètement

```bash
# Flutter
cd pharmago
flutter clean
rm -rf .dart_tool build
flutter pub get

# Backend
cd PharmaGoBackend
dotnet clean
rm -rf bin obj
dotnet restore
dotnet build
```

---

## 📊 MONITORING

### Logs Backend en temps réel

```bash
cd PharmaGoBackend
dotnet run 2>&1 | tee backend.log
```

### Logs Flutter en temps réel

```bash
cd pharmago
flutter run 2>&1 | tee flutter.log
```

### Surveiller les CRON

```bash
# Dans les logs backend, chercher :
cd PharmaGoBackend
dotnet run | grep "🕐\|🔄\|✅"
```

---

## 🎨 FORMATAGE & QUALITÉ

### Flutter

```bash
cd pharmago

# Formater
flutter format lib/

# Analyser
flutter analyze

# Linter
dart analyze
```

### .NET

```bash
cd PharmaGoBackend

# Formater
dotnet format

# Analyser
dotnet build /p:TreatWarningsAsErrors=true
```

---

## 🔐 SÉCURITÉ

### Rechercher les clés API exposées

```bash
# Rechercher les clés Google Maps
grep -r "AIza" pharmago/

# Rechercher les secrets
grep -r "password\|secret\|key" --include="*.dart" --include="*.cs" pharmago/ PharmaGoBackend/
```

### Vérifier .gitignore

```bash
# Fichiers qui ne devraient PAS être commités
git ls-files | grep -E "appsettings.json|\.env|secrets"
```

---

## 📈 PERFORMANCE

### Analyser la taille de l'app

```bash
cd pharmago

# Android
flutter build apk --analyze-size

# iOS
flutter build ios --analyze-size
```

### Profiler l'app

```bash
cd pharmago
flutter run --profile
```

---

## 📚 DOCUMENTATION

### Générer la documentation Dart

```bash
cd pharmago
dart doc .
```

### Swagger Backend

Accessible sur : http://localhost:5000 (quand backend lancé)

---

## 🎯 RACCOURCIS RAPIDES

```bash
# Installation complète
./install.sh

# Lancer backend
cd PharmaGoBackend && dotnet run

# Lancer Flutter iOS
cd pharmago && flutter run -d ios

# Build release Android
cd pharmago && flutter build apk --release

# Tests complets
cd pharmago && flutter test && cd ../PharmaGoBackend && dotnet test

# Nettoyer tout
cd pharmago && flutter clean && cd ../PharmaGoBackend && dotnet clean
```

---

## 📞 AIDE

Pour plus d'informations :
- 📖 [`MIGRATION_OSM_GUIDE.md`](./MIGRATION_OSM_GUIDE.md) - Guide complet
- 📋 [`INDEX_DOCUMENTATION.md`](./INDEX_DOCUMENTATION.md) - Index documentation
- 📊 [`SYNTHESE_MIGRATION.md`](./SYNTHESE_MIGRATION.md) - Vue d'ensemble

---

**✅ Toutes les commandes dont vous avez besoin !**
