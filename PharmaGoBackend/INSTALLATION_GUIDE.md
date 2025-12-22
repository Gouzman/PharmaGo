# 🚀 GUIDE D'INSTALLATION RAPIDE - STRATÉGIE DATA V2.0

## ✅ Prérequis

- ✅ .NET 8.0 SDK installé
- ✅ Compte Supabase actif
- ✅ Projet PharmaGo configuré

---

## 📦 ÉTAPE 1 : Installer HtmlAgilityPack

```bash
cd PharmaGoBackend
dotnet add package HtmlAgilityPack
```

---

## 🗄️ ÉTAPE 2 : Migrer la base de données Supabase

1. Ouvrir Supabase Dashboard
2. Aller dans **SQL Editor**
3. Copier-coller le contenu de `supabase_migration_v2_history_confidence.sql`
4. Cliquer sur **Run**

**Vérifier le succès** :
```sql
-- Devrait retourner ~514 pharmacies
SELECT COUNT(*) FROM pharmacies;

-- Nouvelles colonnes doivent exister
SELECT confidence_score, data_sources FROM pharmacies LIMIT 1;

-- Nouvelles tables doivent exister
SELECT COUNT(*) FROM pharmacy_history;
SELECT COUNT(*) FROM pharmacy_metadata;
```

---

## ⚙️ ÉTAPE 3 : Mettre à jour Program.cs

Ajouter les nouveaux services dans `/Users/gouzman/Documents/pharma/PharmaGoBackend/src/Program.cs` :

```csharp
// Après les services existants, ajouter :

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOUVEAUX SERVICES STRATÉGIE DATA V2.0
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Service de scraping pharmacies-de-garde.ci
builder.Services.AddSingleton<PharmaciesDeGardeScraperService>();

// Service de fusion intelligente
builder.Services.AddSingleton<PharmacyDataMergerService>();

// Repository historique
builder.Services.AddSingleton<PharmacyHistoryRepository>();

// ⏰ CRON Service hebdomadaire (PRINCIPAL)
builder.Services.AddHostedService<WeeklyDataSyncService>();

// Note : Vous pouvez DÉSACTIVER les anciens CRON si vous voulez :
// - PharmacyUpdater (remplacé par WeeklyDataSyncService)
// - GuardUpdater (remplacé par WeeklyDataSyncService)
```

**Exemple complet** :
```csharp
// Services Infrastructure
builder.Services.AddSingleton(sp => 
{
    var supabaseUrl = builder.Configuration["Supabase:Url"]!;
    var supabaseKey = builder.Configuration["Supabase:ServiceKey"]!;
    var client = new SupabaseClientService(supabaseUrl, supabaseKey);
    client.InitializeAsync().Wait();
    return client;
});

builder.Services.AddSingleton<OverpassService>();
builder.Services.AddSingleton<OsmSyncService>();
builder.Services.AddSingleton<PharmacyRepository>();

// ✨ NOUVEAUX SERVICES
builder.Services.AddSingleton<PharmaciesDeGardeScraperService>();
builder.Services.AddSingleton<PharmacyDataMergerService>();
builder.Services.AddSingleton<PharmacyHistoryRepository>();

// Services Application
builder.Services.AddSingleton<PharmacySyncService>();

// ⏰ CRON Services
builder.Services.AddHostedService<WeeklyDataSyncService>();

// API Controllers
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
```

---

## 🏃 ÉTAPE 4 : Lancer le backend

```bash
cd /Users/gouzman/Documents/pharma/PharmaGoBackend
dotnet run
```

**Logs attendus** :

```
╔═══════════════════════════════════════════════════════╗
║   🕐 WEEKLY DATA SYNC SERVICE - DÉMARRÉ              ║
║   📅 Planification : Dimanche 22h00 UTC              ║
╚═══════════════════════════════════════════════════════╝

🚀 Exécution initiale au démarrage...

╔═══════════════════════════════════════════════════════╗
║                                                       ║
║       🌍 SYNCHRONISATION HEBDOMADAIRE COMPLÈTE       ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 ÉTAPE 1/4 : Synchronisation OpenStreetMap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🗺️  SYNCHRONISATION OPENSTREETMAP → SUPABASE
📍 Étape 1/3 : Récupération depuis OpenStreetMap...
✅ 514 pharmacie(s) récupérée(s) depuis OSM

📍 Étape 2/3 : Récupération des données existantes Supabase...
✅ 514 pharmacie(s) existante(s) dans Supabase

📍 Étape 3/3 : Synchronisation avec Supabase...
✅ OSM Sync : 514 pharmacie(s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 ÉTAPE 2/4 : Scraping pharmacies-de-garde.ci
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏥 SCRAPING PHARMACIES-DE-GARDE.CI (OFFICIEL)
📍 Scraping Abidjan...
   ✅ 12 pharmacie(s) de garde trouvée(s)
📍 Scraping Bouaké...
   ✅ 2 pharmacie(s) de garde trouvée(s)

🎯 TOTAL : 14 pharmacie(s) de garde récupérée(s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 ÉTAPE 3/4 : Fusion OSM + Garde
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔀 FUSION INTELLIGENTE DES DONNÉES
✅ Fusion : 11 matchés, 3 non-matchés

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 ÉTAPE 4/4 : Génération JSON + Upload Supabase
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ JSON généré : https://wglrryhnrqninxzrmowh.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json

╔═══════════════════════════════════════════════════════╗
║                                                       ║
║           ✅ SYNCHRONISATION TERMINÉE !              ║
║                                                       ║
║   ⏱️  Durée : 12.3 minutes                           ║
║   📊 OSM : 514 pharmacies                            ║
║   🏥 Garde : 14 pharmacies                           ║
║   🔀 Fusion : 11 matchés                             ║
║   ⚠️  À réviser : 3 conflits                         ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

⏰ Prochaine sync : 2025-12-21 22:00 UTC (dans 168.0h)
```

---

## ✅ ÉTAPE 5 : Vérifier le résultat

### 1️⃣ Vérifier le JSON généré

Ouvrir dans le navigateur :
```
https://wglrryhnrqninxzrmowh.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json
```

**Structure attendue** :
```json
{
  "version": 1734300000000,
  "generatedAt": "2025-12-19T22:00:00Z",
  "pharmacies": [
    {
      "id": "osm_node_123456",
      "name": "Pharmacie Centrale Cocody",
      "lat": 5.345317,
      "lng": -4.024429,
      "commune": "Cocody",
      "isGuard": true,
      "confidenceScore": 92,
      "dataSources": "osm,pharmacies-de-garde.ci",
      "updatedAt": "2025-12-19T22:05:00Z"
    }
  ]
}
```

### 2️⃣ Vérifier l'historique dans Supabase

```sql
-- Voir les derniers changements
SELECT * FROM pharmacy_history 
ORDER BY modified_at DESC 
LIMIT 10;

-- Voir les pharmacies de garde ajoutées
SELECT * FROM pharmacy_history 
WHERE change_type = 'guard_status_changed' 
  AND new_value = 'true'
ORDER BY modified_at DESC;
```

### 3️⃣ Vérifier les scores de confiance

```sql
-- Pharmacies avec meilleur score
SELECT name, commune, confidence_score, data_sources, is_guard
FROM pharmacies
ORDER BY confidence_score DESC
LIMIT 20;

-- Pharmacies de garde avec leurs scores
SELECT name, commune, confidence_score, is_guard
FROM pharmacies
WHERE is_guard = true
ORDER BY confidence_score DESC;
```

---

## 🔧 DÉPANNAGE

### ❌ Erreur : "Type 'PharmaciesDeGardeScraperService' not found"

**Solution** : Vérifier que HtmlAgilityPack est installé
```bash
dotnet add package HtmlAgilityPack
dotnet restore
dotnet build
```

### ❌ Erreur : "Table 'pharmacy_history' does not exist"

**Solution** : Exécuter la migration SQL dans Supabase

### ❌ Scraping retourne 0 pharmacies

**Causes possibles** :
1. Site pharmacies-de-garde.ci inaccessible ou changé de structure
2. Bloqué par firewall/anti-bot

**Solutions** :
1. Vérifier l'URL : `https://www.pharmacies-de-garde.ci`
2. Adapter les sélecteurs CSS dans `PharmaciesDeGardeScraperService.cs`
3. Tester manuellement dans le navigateur

### ❌ Aucune pharmacie matchée lors de la fusion

**Solution** : Logs de debug
```csharp
// Dans PharmacyDataMergerService.cs, ligne ~70
Console.WriteLine($"🔍 Recherche match pour: {guardInfo.Name} ({guardInfo.City})");
Console.WriteLine($"   OSM candidates: {osmPharmacies.Count}");
```

---

## 📅 PLANIFICATION CRON

Le service s'exécute automatiquement :
- **Quand** : Dimanche 22h00 UTC
- **Fréquence** : 1 fois / semaine
- **Durée** : ~10-15 minutes

**Forcer une exécution manuelle** :
```csharp
// Créer un endpoint API (optionnel)
[HttpPost("api/admin/force-sync")]
public async Task<IActionResult> ForceSync(
    [FromServices] WeeklyDataSyncService syncService)
{
    await syncService.ForceRunAsync();
    return Ok(new { message = "Synchronisation déclenchée" });
}
```

---

## 🎉 SUCCÈS !

Si vous voyez ces logs, tout fonctionne :
```
✅ SYNCHRONISATION TERMINÉE !
⏱️  Durée : X.X minutes
📊 OSM : 514 pharmacies
🏥 Garde : XX pharmacies
🔀 Fusion : XX matchés
```

**Prochaines étapes** :
1. ✅ Vérifier que Flutter télécharge le nouveau JSON
2. ✅ Tester l'affichage des pharmacies de garde
3. ✅ Consulter les scores de confiance
4. ✅ Réviser les conflits dans `entries_needing_review`

---

## 📞 Support

En cas de problème :
1. Vérifier les logs du backend
2. Consulter `STRATEGIE_DATA_V2_README.md`
3. Vérifier la table `pharmacy_history` dans Supabase

**Bon déploiement ! 🚀**
