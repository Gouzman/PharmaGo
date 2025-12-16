# 🗺️ MIGRATION VERS OPENSTREETMAP - GUIDE TECHNIQUE

## 📋 Vue d'ensemble

Le backend PharmaGo a été migré pour utiliser **OpenStreetMap (OSM)** comme source de données au lieu de données de test statiques. Cette migration permet d'obtenir des **données réelles et gratuites** sur les pharmacies d'Abidjan.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   FLUX DE DONNÉES                           │
└─────────────────────────────────────────────────────────────┘

OpenStreetMap (Overpass API)
          │
          │ 1. Récupération (HTTP)
          ▼
┌──────────────────────┐
│  OverpassService     │  → Récupère les pharmacies OSM
└──────────────────────┘
          │
          │ 2. Normalisation
          ▼
┌──────────────────────┐
│  OsmSyncService      │  → Synchronise OSM → Supabase
└──────────────────────┘
          │
          │ 3. Upsert
          ▼
┌──────────────────────┐
│  Supabase PostgreSQL │  → Base de données
└──────────────────────┘
          │
          │ 4. Génération JSON
          ▼
┌──────────────────────┐
│ PharmacySyncService  │  → Génère pharmacies.json
└──────────────────────┘
          │
          │ 5. Upload
          ▼
┌──────────────────────┐
│ Supabase Storage     │  → Fichier JSON public
└──────────────────────┘
          │
          │ 6. Téléchargement
          ▼
┌──────────────────────┐
│   App Flutter        │  → Affichage carte OSM
└──────────────────────┘
```

---

## 🆕 Nouveaux services créés

### 1️⃣ **OverpassService** (`Infrastructure/OverpassService.cs`)

**Rôle** : Récupère les pharmacies depuis OpenStreetMap via l'API Overpass.

**Méthodes principales** :
- `FetchPharmaciesAsync()` : Récupère toutes les pharmacies d'Abidjan
- `MapToPharmacy()` : Convertit un élément OSM en objet Pharmacy
- `DetermineCommune()` : Détermine la commune en fonction des coordonnées GPS

**Paramètres OSM** :
- **Bounding Box Abidjan** : `[5.20, -4.20, 5.45, -3.90]`
- **Tag OSM** : `amenity=pharmacy`
- **API utilisée** : `https://overpass-api.de/api/interpreter`
- **Timeout** : 2 minutes

**Données extraites** :
- `name` : Nom de la pharmacie
- `lat/lon` : Coordonnées GPS
- `addr:*` : Adresse, ville, quartier
- `phone` : Numéro de téléphone
- `opening_hours` : Horaires d'ouverture

**Exemple de requête Overpass** :
```
[out:json][timeout:60];
(
  node["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
  way["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
);
out center body;
>;
out skel qt;
```

---

### 2️⃣ **OsmSyncService** (`Infrastructure/OsmSyncService.cs`)

**Rôle** : Synchronise les pharmacies OSM avec Supabase (UPSERT).

**Méthodes principales** :
- `SyncPharmaciesFromOsmAsync()` : Lance la synchronisation complète
- `UpsertPharmaciesAsync()` : Insère ou met à jour les pharmacies

**Logique UPSERT** :
1. Récupère les pharmacies OSM
2. Récupère les pharmacies existantes dans Supabase
3. Pour chaque pharmacie OSM :
   - Si l'ID existe → **UPDATE**
   - Si l'ID n'existe pas → **INSERT**

**Format ID** : `osm_{type}_{id}` (ex: `osm_node_123456789`)

---

### 3️⃣ **Méthodes ajoutées dans SupabaseClientService**

- `InsertPharmacyAsync(Pharmacy pharmacy)` : Insère une nouvelle pharmacie
- `UpdatePharmacyAsync(Pharmacy pharmacy)` : Met à jour une pharmacie existante

---

## 🔄 Mise à jour du PharmacySyncService

La méthode `FullSyncAsync()` a été modifiée pour inclure la synchronisation OSM :

**Nouveau flux** :
1. **Phase 1** : Synchronisation OSM → Supabase
2. **Phase 2** : Synchronisation des gardes
3. **Phase 3** : Génération et upload du JSON

---

## ⏰ Automatisation (CRON)

### PharmacyUpdater modifié

**Ancienne fréquence** : Toutes les 6 heures  
**Nouvelle fréquence** : **1 fois par jour à 3h du matin**

**Justification** :
- Les données OSM ne changent pas toutes les heures
- Évite de surcharger l'API Overpass
- Mise à jour nocturne pour minimiser l'impact

**Comportement** :
- ✅ Exécution immédiate au démarrage (pour initialiser les données)
- ⏰ Ensuite, planification quotidienne à 3h00
- 🔁 En cas d'erreur : retry après 1 heure

---

## 🌐 Nouveaux endpoints API

### `POST /api/pharmacies/sync`
Déclenche une synchronisation complète (existante, mais maintenant inclut OSM).

**Réponse** :
```json
{
  "success": true,
  "url": "https://[...]/storage/v1/object/public/pharmacy_data/pharmacies.json",
  "syncedAt": "2025-12-15T10:30:00Z",
  "duration": 12.5
}
```

### `POST /api/pharmacies/sync/osm` *(nouveau)*
Force immédiatement la synchronisation depuis OpenStreetMap.

**Réponse** :
```json
{
  "success": true,
  "message": "Synchronisation OpenStreetMap démarrée"
}
```

---

## 📦 Dépendances ajoutées

Aucune nouvelle dépendance NuGet ! Utilisation de :
- `HttpClient` (natif .NET)
- `System.Text.Json` (natif .NET)

---

## 🚀 Déploiement

### Étape 1 : Vérifier la configuration Supabase

Assurez-vous que `appsettings.json` contient :
```json
{
  "Supabase": {
    "Url": "https://[votre-projet].supabase.co",
    "Key": "[votre-clé-anon]"
  }
}
```

### Étape 2 : Créer le bucket Supabase Storage

Le bucket `pharmacy_data` sera créé automatiquement au premier upload.  
Ou créez-le manuellement dans l'interface Supabase :
- Nom : `pharmacy_data`
- Public : **Oui**

### Étape 3 : Lancer le backend

```bash
cd PharmaGoBackend
dotnet run
```

### Étape 4 : Déclencher la première synchronisation

**Option A : Automatique**  
La synchronisation se déclenche automatiquement au démarrage.

**Option B : Manuelle**  
Appelez l'endpoint :
```bash
curl -X POST https://votre-api.com/api/pharmacies/sync/osm
```

### Étape 5 : Vérifier le fichier JSON

L'URL du JSON sera disponible à :
```
https://[projet].supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json
```

---

## 📊 Format du fichier JSON

```json
{
  "version": 638700000000000000,
  "generated_at": "2025-12-15T10:30:00Z",
  "pharmacies": [
    {
      "id": "osm_node_123456789",
      "name": "Pharmacie du Plateau",
      "lat": 5.3267,
      "lng": -4.0249,
      "address": "Boulevard de la République",
      "commune": "Plateau",
      "quartier": "Centre",
      "phone": "+2252701234567",
      "assurances": [],
      "open_hours": {
        "open": "08:00",
        "close": "20:00"
      },
      "is_guard": false,
      "updated_at": "2025-12-15T10:30:00Z"
    }
  ]
}
```

---

## 🔍 Mapping des communes d'Abidjan

Le service utilise une approximation géographique pour déterminer la commune :

| Commune      | Latitude Min | Latitude Max | Longitude Min | Longitude Max |
|--------------|--------------|--------------|---------------|---------------|
| Plateau      | 5.32         | 5.34         | -4.03         | -4.01         |
| Cocody       | 5.33         | 5.38         | -3.98         | -3.90         |
| Yopougon     | 5.30         | 5.36         | -4.12         | -4.05         |
| Abobo        | 5.40         | 5.45         | -4.05         | -4.00         |
| Adjamé       | 5.34         | 5.37         | -4.04         | -4.01         |
| Koumassi     | 5.28         | 5.32         | -3.96         | -3.92         |
| Marcory      | 5.28         | 5.31         | -4.01         | -3.98         |
| Treichville  | 5.29         | 5.32         | -4.03         | -4.00         |
| Port-Bouët   | 5.23         | 5.28         | -3.97         | -3.90         |
| Attécoubé    | 5.32         | 5.35         | -4.08         | -4.04         |

**Fallback** : Si aucune correspondance → "Abidjan"

---

## ✅ Avantages de cette architecture

1. ✅ **100% Gratuit** : Aucune API payante (Google, etc.)
2. ✅ **Données réelles** : Pharmacies issues de la communauté OSM
3. ✅ **Scalable** : Peut être étendu à d'autres villes en changeant la bounding box
4. ✅ **Pas de modification Flutter** : Le frontend continue de fonctionner tel quel
5. ✅ **Cache efficace** : JSON versionné pour détecter les changements
6. ✅ **Mise à jour automatique** : CRON quotidien
7. ✅ **Maintenable** : Code propre, commenté, prêt pour la production

---

## 🛠️ Maintenance

### Ajouter une nouvelle ville

Modifier `OverpassService.cs` :
```csharp
private const double MinLat = 6.80; // Bouaké
private const double MinLon = -5.10;
private const double MaxLat = 6.90;
private const double MaxLon = -5.00;
```

### Augmenter la fréquence de synchronisation

Modifier `PharmacyUpdater.cs` :
```csharp
private readonly TimeSpan _targetTime = new TimeSpan(2, 0, 0); // 2h du matin
```

### Ajuster le timeout Overpass

Modifier `OverpassService.cs` :
```csharp
_httpClient.Timeout = TimeSpan.FromMinutes(5); // 5 minutes
```

---

## 🐛 Troubleshooting

### Problème : Aucune pharmacie récupérée depuis OSM

**Causes possibles** :
1. Bounding box incorrecte
2. Pas de pharmacies taguées dans OSM
3. Timeout de l'API Overpass

**Solution** :
- Tester la requête Overpass manuellement sur https://overpass-turbo.eu/
- Vérifier les logs du backend

### Problème : Erreur d'upload Supabase

**Causes possibles** :
1. Bucket inexistant
2. Clé Supabase invalide
3. Permissions Storage

**Solution** :
- Vérifier la configuration `appsettings.json`
- Créer le bucket manuellement
- Vérifier les permissions dans Supabase Dashboard

### Problème : Communes mal détectées

**Solution** :
- Affiner les bounding boxes dans `DetermineCommune()`
- Ou utiliser une API de geocoding inverse (Nominatim OSM)

---

## 📝 Logs de synchronisation

Exemple de logs lors d'une synchronisation complète :

```
╔═══════════════════════════════════════════════════════╗
║     🗺️  SYNCHRONISATION OPENSTREETMAP → SUPABASE    ║
╚═══════════════════════════════════════════════════════╝

📍 Étape 1/3 : Récupération depuis OpenStreetMap...
🔄 Récupération des pharmacies depuis OpenStreetMap...
✅ 45 pharmacie(s) récupérée(s) depuis OSM

📍 Étape 2/3 : Récupération des données existantes Supabase...
✅ 8 pharmacie(s) existante(s) dans Supabase

📍 Étape 3/3 : Synchronisation avec Supabase...
  ➕ Ajout: Pharmacie du Plateau
  ➕ Ajout: Pharmacie Cocody Centre
  🔄 Mise à jour: Pharmacie Yopougon
  ...

╔═══════════════════════════════════════════════════════╗
║  ✅ SYNCHRONISATION TERMINÉE EN 8.5s
║  📊 45 récupérées | 45 synchronisées
╚═══════════════════════════════════════════════════════╝

📍 PHASE 2 : Synchronisation des gardes
✅ Phase 2 terminée

📍 PHASE 3 : Génération et upload du JSON
🔄 Génération du JSON des pharmacies...
✅ JSON généré avec succès - 45 pharmacie(s)
📤 Upload du JSON vers Supabase Storage...
✅ JSON uploadé avec succès: https://[...]/pharmacies.json
✅ Phase 3 terminée

✅ Synchronisation complète terminée en 12.3s
```

---

## 🎯 Prochaines étapes possibles

1. **Améliorer le mapping des communes** avec une API de geocoding inverse
2. **Ajouter d'autres villes** (Bouaké, Yamoussoukro, San-Pedro...)
3. **Enrichir les données** avec des photos, avis, etc.
4. **Monitoring** : Ajouter des alertes en cas d'échec de synchronisation
5. **Cache local** : Éviter de refaire l'appel Overpass si les données n'ont pas changé

---

## 📚 Ressources

- **Overpass API** : https://overpass-api.de/
- **Overpass Turbo** (test de requêtes) : https://overpass-turbo.eu/
- **Documentation OSM Tags** : https://wiki.openstreetmap.org/wiki/Tag:amenity=pharmacy
- **Supabase Storage** : https://supabase.com/docs/guides/storage

---

## ✅ Checklist de migration

- [x] OverpassService créé
- [x] OsmSyncService créé
- [x] Méthodes Insert/Update dans SupabaseClientService
- [x] PharmacySyncService mis à jour
- [x] PharmacyUpdater adapté (1x/jour)
- [x] Endpoint API `/sync/osm` créé
- [x] Services enregistrés dans Program.cs
- [x] Compilation réussie
- [ ] Tests de synchronisation OSM
- [ ] Vérification du JSON généré
- [ ] Validation dans l'app Flutter

---

**Auteur** : GitHub Copilot  
**Date** : 15 décembre 2025  
**Version** : 1.0.0
