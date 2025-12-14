# 🏥 PharmaGo Backend API

Backend .NET 8 Web API pour l'application mobile PharmaGo.

## 🎯 Fonctionnalités

- ✅ Gestion complète des pharmacies via Supabase
- ✅ Génération automatique d'un fichier JSON versionné
- ✅ Stockage dans Supabase Storage (bucket `pharmacy_data`)
- ✅ Mise à jour automatique des pharmacies de garde (CRON quotidien)
- ✅ Synchronisation automatique toutes les 6 heures
- ✅ API REST complète pour Flutter

## 📁 Architecture

```
PharmaGoBackend/
├── src/
│   ├── Domain/
│   │   ├── Pharmacy.cs
│   │   └── GuardSchedule.cs
│   ├── Infrastructure/
│   │   ├── SupabaseClientService.cs
│   │   └── PharmacyRepository.cs
│   ├── Application/
│   │   └── PharmacySyncService.cs
│   ├── Cron/
│   │   ├── GuardUpdater.cs
│   │   └── PharmacyUpdater.cs
│   ├── API/
│   │   └── Controllers/
│   │       └── PharmaciesController.cs
│   └── Program.cs
├── appsettings.json
└── PharmaGo.csproj
```

## 🚀 Installation

### 1. Prérequis

- .NET 8 SDK
- Compte Supabase avec projet configuré

### 2. Configuration

Éditez `appsettings.json` :

```json
{
  "Supabase": {
    "Url": "https://YOUR_PROJECT.supabase.co",
    "Key": "YOUR_ANON_KEY"
  }
}
```

### 3. Structure de la base de données Supabase

**Table `pharmacies`:**

```sql
CREATE TABLE pharmacies (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  address TEXT,
  phone TEXT,
  commune TEXT,
  quartier TEXT,
  assurances TEXT[],
  is_guard BOOLEAN DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Table `guard_schedules`:**

```sql
CREATE TABLE guard_schedules (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id TEXT REFERENCES pharmacies(id),
  start TIMESTAMP WITH TIME ZONE NOT NULL,
  end TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Bucket Storage:**

Créer un bucket public nommé `pharmacy_data` dans Supabase Storage.

### 4. Restaurer les packages

```bash
dotnet restore
```

### 5. Lancer le serveur

```bash
dotnet run
```

Le serveur démarre sur : `http://localhost:5000`

## 📡 Endpoints API

### Endpoint principal (Flutter)

**GET /api/pharmacies/latest**

Retourne l'URL publique du JSON versionné.

```json
{
  "url": "https://your-project.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json",
  "cacheMaxAge": 21600
}
```

### Autres endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/pharmacies` | Toutes les pharmacies |
| GET | `/api/pharmacies/{id}` | Pharmacie par ID |
| GET | `/api/pharmacies/guard` | Pharmacies de garde |
| GET | `/api/pharmacies/commune/{commune}` | Par commune |
| GET | `/api/pharmacies/nearby?lat={lat}&lng={lng}&radius={km}` | À proximité |
| POST | `/api/pharmacies/sync` | Force synchronisation |
| POST | `/api/pharmacies/guard/update` | Force mise à jour gardes |
| GET | `/api/pharmacies/health` | Santé du backend |

## ⏰ Services CRON

### GuardUpdater
- **Fréquence** : Quotidien à 00:00 UTC
- **Fonction** : Met à jour le statut `is_guard` des pharmacies

### PharmacyUpdater
- **Fréquence** : Toutes les 6 heures
- **Fonction** : Génère et upload le JSON dans Supabase Storage

## 📦 Format du JSON généré

```json
{
  "version": 638712345678901234,
  "generated_at": "2025-12-13T10:30:00Z",
  "pharmacies": [
    {
      "id": "ph_001",
      "name": "Pharmacie Centrale",
      "lat": 33.5731,
      "lng": -7.5898,
      "address": "123 Rue Mohammed V",
      "commune": "Casablanca",
      "quartier": "Maarif",
      "phone": "+212 522 123456",
      "assurances": ["CNSS", "CNOPS", "RMA"],
      "open_hours": {
        "open": "08:00",
        "close": "20:00"
      },
      "is_guard": true,
      "updated_at": "2025-12-13T10:00:00Z"
    }
  ]
}
```

## 🔧 Développement

### Build

```bash
dotnet build
```

### Publish

```bash
dotnet publish -c Release -o ./publish
```

## 🗺️ Intégration Flutter

Dans votre app Flutter, chargez le JSON :

```dart
final response = await http.get(Uri.parse(
  'https://your-backend.com/api/pharmacies/latest'
));
final data = jsonDecode(response.body);
final jsonUrl = data['url'];

// Télécharger le JSON
final pharmaciesResponse = await http.get(Uri.parse(jsonUrl));
final pharmaciesData = jsonDecode(pharmaciesResponse.body);
```

## 📝 Licence

MIT

## 👨‍💻 Auteur

PharmaGo Team
