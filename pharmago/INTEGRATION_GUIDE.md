# 🏥 PharmaGo - Système de Gestion des Pharmacies

## 📋 Vue d'ensemble

PharmaGo est une application mobile Flutter complète avec un backend .NET 8 pour la gestion, la mise à jour automatique et la diffusion des données de pharmacies en Côte d'Ivoire.

## 🏗️ Architecture

### Backend (.NET 8 Web API + Supabase)
```
PharmaGoBackend/
├── src/
│   ├── Domain/           # Modèles métier (Pharmacy, GuardSchedule)
│   ├── Infrastructure/   # Supabase (PostgreSQL + Storage)
│   ├── Application/      # Services métier (PharmacySyncService)
│   ├── Cron/            # Tâches automatiques (CRON)
│   └── API/             # Controllers REST
```

**Technologies :**
- .NET 8 Web API
- Supabase PostgreSQL (base de données)
- Supabase Storage (fichiers JSON)
- Supabase Realtime (synchronisation temps réel)

**Fonctionnalités principales :**
1. **Synchronisation automatique** : CRON toutes les 6 heures pour générer le JSON des pharmacies
2. **Mise à jour des gardes** : CRON quotidien à 00:00 UTC pour actualiser les pharmacies de garde
3. **Système de versioning** : Chaque JSON a une version (timestamp) pour détecter les mises à jour
4. **API REST** : Endpoint `/api/pharmacies/latest` pour récupérer les données

### Frontend (Flutter)
```
pharmago/lib/
├── models/              # Modèles de données (Pharmacy, OpeningHours)
├── providers/           # State Management (PharmacyProvider)
├── services/            # Services métier (PharmacyDataService)
├── ui/                  # Interface utilisateur
│   ├── pages/          # Pages (HomePage, PharmacyDetailPage)
│   └── widgets/        # Composants réutilisables
└── utils/              # Utilitaires (LocationService)
```

**Technologies :**
- Flutter SDK ^3.8.1
- Provider (state management)
- Geolocator (localisation GPS)
- Google Maps Flutter (navigation)
- HTTP (communication backend)
- SharedPreferences (cache local)

## 🎯 Fonctionnalités

### 1. Chargement intelligent des pharmacies
- **Cache local** : Les données sont stockées en cache avec SharedPreferences
- **Synchronisation auto** : Vérification des mises à jour à chaque lancement
- **Mode offline** : Fonctionne sans connexion avec les données en cache
- **Versioning** : Détection automatique des nouvelles données via timestamps

### 2. Localisation et distance
- **Position GPS** : Récupération automatique de la position utilisateur
- **Calcul de distance** : Formule de Haversine pour calculer la distance jusqu'aux pharmacies
- **Filtre proximité** : Affichage des pharmacies dans un rayon de 5km
- **Tri automatique** : Pharmacies triées par distance croissante

### 3. Gestion des pharmacies de garde
- **Badge visuel** : Badge orange "GARDE" sur les cartes
- **Bordure distinctive** : Contour orange pour les pharmacies de garde
- **Icône spéciale** : Icon `medical_services` au lieu de `local_pharmacy`
- **Mise à jour quotidienne** : Actualisation automatique via CRON backend

### 4. Interface utilisateur
- **Design moderne** : Material Design 3 avec animations fluides
- **Gradient personnalisé** : Fond dégradé vert/blanc
- **Carrousel publicitaire** : Bannières avec indicateurs de pagination
- **Carte interactive** : Affichage des détails (nom, adresse, horaires, distance)
- **Navigation intégrée** : Bouton de navigation vers Google Maps
- **Bouton refresh** : Synchronisation manuelle avec indicateur de chargement

### 5. Détails des pharmacies
Chaque carte de pharmacie affiche :
- **Nom** de la pharmacie
- **Quartier/Commune**
- **Adresse complète** + numéro de téléphone
- **Statut** : Ouvert/Fermé (point vert/rouge)
- **Horaires** : "Ferme à XX:XX" / "Ouvre à XX:XX"
- **Distance** : Calculée en temps réel depuis la position GPS
- **Badge DE GARDE** : Si la pharmacie est de garde aujourd'hui

## 🔧 Configuration

### Backend (.NET 8)

#### 1. Prérequis
```bash
dotnet --version  # Doit être >= 8.0
```

#### 2. Configuration Supabase
Créez un fichier `appsettings.json` :
```json
{
  "Supabase": {
    "Url": "https://VOTRE_PROJET.supabase.co",
    "Key": "VOTRE_SUPABASE_ANON_KEY",
    "ServiceKey": "VOTRE_SUPABASE_SERVICE_ROLE_KEY"
  },
  "ConnectionStrings": {
    "SupabaseDb": "Host=db.VOTRE_PROJET.supabase.co;Database=postgres;Username=postgres;Password=VOTRE_MOT_DE_PASSE"
  }
}
```

#### 3. Structure de la base de données
```sql
CREATE TABLE pharmacies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  address TEXT,
  commune TEXT,
  quartier TEXT,
  phone TEXT,
  assurances TEXT[],
  open_hours JSONB,
  is_guard BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE guard_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID REFERENCES pharmacies(id),
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. Bucket Supabase Storage
Créez un bucket public nommé `pharmacy_data` dans Supabase Storage.

#### 5. Lancement du backend
```bash
cd PharmaGoBackend/src
dotnet restore
dotnet build
dotnet run --project API
```

Le backend sera accessible sur `https://localhost:5001` ou `http://localhost:5000`.

### Frontend (Flutter)

#### 1. Prérequis
```bash
flutter --version  # Doit être >= 3.8.1
```

#### 2. Installation des dépendances
```bash
cd pharmago
flutter pub get
```

#### 3. Configuration du backend
Modifiez `lib/services/pharmacy_data_service.dart` :
```dart
static const String baseUrl = 'https://VOTRE_BACKEND_URL';
// OU pour développement local :
static const String baseUrl = 'http://localhost:5000';
```

#### 4. Configuration Google Maps
Ajoutez votre clé API Google Maps :

**Android** : `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="VOTRE_CLE_API_GOOGLE_MAPS"/>
```

**iOS** : `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("VOTRE_CLE_API_GOOGLE_MAPS")
```

#### 5. Lancement de l'application
```bash
flutter run
```

## 📊 Flux de données

```
┌─────────────────────────────────────────────────────────┐
│                   BACKEND (.NET 8)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐      ┌──────────────────┐           │
│  │ CRON (6h)    │──────▶ PharmacySyncService│          │
│  │              │      │ - Génère JSON     │          │
│  └──────────────┘      │ - Upload Storage  │          │
│                        └──────────────────┘          │
│                                 │                       │
│  ┌──────────────┐              ▼                       │
│  │ CRON (00:00) │      ┌──────────────────┐           │
│  │ GuardUpdater │──────▶ Supabase DB      │           │
│  └──────────────┘      │ + Supabase Storage│          │
│                        └──────────────────┘          │
│                                 │                       │
│                                 ▼                       │
│                        ┌──────────────────┐           │
│                        │ REST API         │           │
│                        │ /api/pharmacies/ │           │
│                        │ latest           │           │
│                        └──────────────────┘           │
└─────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────┐
│                 FRONTEND (Flutter)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐     ┌──────────────────┐        │
│  │ PharmacyDataService│────▶ HTTP Request     │        │
│  │ - Cache local    │     │ GET /latest      │        │
│  │ - Versioning     │     └──────────────────┘        │
│  └──────────────────┘              │                   │
│           │                        │                   │
│           ▼                        ▼                   │
│  ┌──────────────────┐     ┌──────────────────┐        │
│  │ SharedPreferences│     │ JSON Response    │        │
│  │ (Cache offline)  │◀────│ {version, data}  │        │
│  └──────────────────┘     └──────────────────┘        │
│           │                                             │
│           ▼                                             │
│  ┌──────────────────┐                                  │
│  │ PharmacyProvider │                                  │
│  │ - State Management│                                 │
│  │ - Tri par distance│                                 │
│  └──────────────────┘                                  │
│           │                                             │
│           ▼                                             │
│  ┌──────────────────┐                                  │
│  │ HomePage         │                                  │
│  │ - Affichage cards │                                 │
│  │ - Loader, refresh │                                 │
│  └──────────────────┘                                  │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Utilisation

### 1. Première ouverture
1. L'application demande la permission de localisation
2. Récupération de la position GPS
3. Chargement des pharmacies depuis le backend
4. Affichage des pharmacies triées par distance

### 2. Actualisation manuelle
Cliquer sur le bouton refresh (⟳) en haut à droite pour :
- Vérifier les mises à jour
- Télécharger les nouvelles données si disponibles
- Afficher un message de confirmation

### 3. Navigation vers une pharmacie
1. Cliquer sur le bouton "Détails" d'une carte
2. Voir les informations détaillées avec carte
3. Cliquer sur l'icône de navigation (⤴)
4. Redirection vers Google Maps pour l'itinéraire

## 📱 Captures d'écran

### HomePage
- **Header** : Avatar utilisateur, nom, bouton carte test, bouton refresh
- **Carrousel** : 5 bannières publicitaires avec pagination
- **Liste pharmacies** : Cartes scrollables avec toutes les infos
- **Loading state** : Loader circulaire + texte "Chargement..."
- **Empty state** : Message + bouton "Réessayer"

### Carte de pharmacie
- **Icône** : Rond avec icon pharmacie (ou medical_services si garde)
- **Badge GARDE** : Orange avec icon shield
- **Nom** + **Badge distance** : Fond vert clair
- **Quartier** + **Adresse/Téléphone**
- **Statut** : Point vert/rouge + "Ouvert"/"Fermé"
- **Horaires** : "Ferme à XX:XX"
- **Bouton Détails** : Fond vert
- **Bouton Navigation** : Icône boussole

## 🔐 Sécurité

- **CORS** configuré pour autoriser les requêtes frontend
- **Validation** des données entrantes (DTO)
- **Timeout HTTP** : 10 secondes max par requête
- **Cache versioning** : Évite les données obsolètes
- **Permissions** : Gestion propre des autorisations GPS

## 🛠️ Maintenance

### Backend
- **Logs** : Consultez les logs des CRON dans la console .NET
- **Monitoring** : Utilisez le dashboard Supabase pour surveiller la DB
- **Scalabilité** : Hébergez sur Azure App Service ou Railway

### Frontend
- **Cache** : Le cache se vide automatiquement si version obsolète
- **Errors** : Les erreurs sont loggées avec `debugPrint`
- **Performance** : Optimisation du calcul de distance (formule simplifiée)

## 📈 Améliorations futures

### Backend
- [ ] Authentification JWT pour sécuriser l'API
- [ ] Webhook pour notifier l'app mobile des nouvelles données
- [ ] Export CSV/Excel des pharmacies
- [ ] Statistiques d'utilisation (nombre de requêtes, pharmacies populaires)

### Frontend
- [ ] Filtres avancés (assurances, commune, ouvert maintenant)
- [ ] Recherche par nom de pharmacie
- [ ] Favoris (pharmacies préférées)
- [ ] Notifications push pour les pharmacies de garde
- [ ] Mode sombre
- [ ] Support multi-langues (FR/EN)

## 🐛 Dépannage

### "Impossible de charger les pharmacies"
1. Vérifiez que le backend est lancé
2. Vérifiez l'URL dans `pharmacy_data_service.dart`
3. Consultez les logs avec `debugPrint`

### "Position GPS indisponible"
1. Vérifiez les permissions dans les paramètres de l'appareil
2. Activez le GPS
3. Redémarrez l'application

### "Aucune pharmacie à proximité"
- Les pharmacies sont filtrées dans un rayon de 5km
- Déplacez-vous ou modifiez le rayon dans `PharmacyProvider`

## 👨‍💻 Développement

### Structure du code
- **Clean Architecture** : Séparation Domain/Infrastructure/Application
- **SOLID principles** : Code modulaire et maintenable
- **Dependency Injection** : Services injectés via DI .NET
- **State Management** : Provider pattern pour Flutter

### Tests
```bash
# Backend
dotnet test

# Frontend
flutter test
```

## 📝 Licence

Ce projet est propriétaire et destiné à un usage interne uniquement.

---

**Développé avec ❤️ pour PharmaGo**
