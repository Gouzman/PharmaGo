# 🏗️ STRATÉGIE DATA PHARMAGO V2.0

## 📋 Vue d'Ensemble

Architecture backend **100% sans API payante** pour récupérer et maintenir des données de pharmacies fiables pour la Côte d'Ivoire.

### 🎯 Objectif
Créer **la source de référence nationale** pour les pharmacies ivoiriennes en combinant :
- ✅ OpenStreetMap (GPS précis)
- ✅ Site officiel pharmacies-de-garde.ci (statut de garde)
- ✅ Historisation complète (audit & rollback)
- ✅ Score de confiance (fiabilité des données)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCES DE DONNÉES                       │
├─────────────────────────────────────────────────────────────┤
│  🗺️ OpenStreetMap        🏥 pharmacies-de-garde.ci         │
│  (Overpass API)          (Scraping hebdomadaire)           │
│  → GPS (lat/lng)         → Statut de garde                  │
│  → Nom, adresse          → Périodes de garde               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   BACKEND .NET 8.0                          │
├─────────────────────────────────────────────────────────────┤
│  📦 OsmSyncService                                          │
│  └─ Récupère 514 pharmacies depuis OSM                     │
│                                                             │
│  🏥 PharmaciesDeGardeScraperService                        │
│  └─ Scrape les pharmacies de garde (15/semaine)           │
│                                                             │
│  🔀 PharmacyDataMergerService                              │
│  └─ Fusion intelligente OSM + Garde                        │
│  └─ Matching par nom + ville + quartier                    │
│  └─ Détection de conflits                                  │
│                                                             │
│  📚 PharmacyHistoryRepository                              │
│  └─ Enregistre tous les changements                        │
│  └─ Permet audit & rollback                                │
│                                                             │
│  📊 Score de confiance (0-100)                             │
│  └─ OSM : +60 | Garde : +20 | Tél : +10 | Historique : +10│
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   SUPABASE POSTGRESQL                       │
├─────────────────────────────────────────────────────────────┤
│  📋 pharmacies (table principale)                          │
│  │  + confidence_score                                     │
│  │  + data_sources                                         │
│                                                             │
│  📜 pharmacy_history (audit trail)                         │
│  │  → Tous les changements                                 │
│  │  → needs_review pour validation humaine                │
│                                                             │
│  🏷️ pharmacy_metadata (qualité)                            │
│  │  → Score de confiance                                   │
│  │  → Validation humaine                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              SUPABASE STORAGE (JSON PUBLIC)                 │
├─────────────────────────────────────────────────────────────┤
│  📦 pharmacies.json (versionné)                            │
│  {                                                          │
│    "version": 1734300000000,                               │
│    "generated_at": "2025-12-19T22:00:00Z",                │
│    "pharmacies": [                                         │
│      {                                                      │
│        "id": "osm_1234",                                   │
│        "name": "Pharmacie Centrale",                       │
│        "is_guard": true,                                   │
│        "confidence_score": 92,                             │
│        ...                                                  │
│      }                                                      │
│    ]                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (READ-ONLY)                  │
├─────────────────────────────────────────────────────────────┤
│  ✅ Télécharge pharmacies.json                             │
│  ✅ Cache local (SharedPreferences)                        │
│  ✅ Affichage avec badges confiance                        │
│  ✅ AUCUN scraping                                          │
│  ✅ AUCUNE logique métier lourde                           │
└─────────────────────────────────────────────────────────────┘
```

---

## ⏰ Planification CRON

| Tâche | Fréquence | Jour/Heure | Service |
|-------|-----------|------------|---------|
| **Sync Complète** | 1x / semaine | Dimanche 22h UTC | `WeeklyDataSyncService` |
| ├─ OSM Sync | ↳ | ↳ | `OsmSyncService` |
| ├─ Scraping Garde | ↳ | ↳ | `PharmaciesDeGardeScraperService` |
| ├─ Fusion | ↳ | ↳ | `PharmacyDataMergerService` |
| └─ Génération JSON | ↳ | ↳ | `PharmacySyncService` |

### 🎯 Pourquoi 1x / semaine ?
- ✅ **Discrétion** : Évite le blocage IP
- ✅ **Stabilité** : Les données changent peu
- ✅ **Économie** : Pas d'API payante nécessaire
- ✅ **Suffisant** : Les gardes changent chaque semaine

---

## 📦 Composants Créés

### 1️⃣ **PharmaciesDeGardeScraperService.cs**
```csharp
// Scrape https://www.pharmacies-de-garde.ci
// Respectueux : User-Agent + délais entre requêtes
// Extraction : Nom, ville, adresse, téléphone, période de garde
```

**Méthodes principales :**
- `FetchGuardPharmaciesAsync()` → Récupère toutes les pharmacies de garde
- `ScrapeCity(string city)` → Scrape une ville spécifique

### 2️⃣ **PharmacyDataMergerService.cs**
```csharp
// Fusion intelligente OSM + Garde
// Matching multi-critères : nom normalisé + ville + quartier
// Score de confiance calculé automatiquement
```

**Méthodes principales :**
- `MergeGuardDataAsync()` → Fusionne OSM + données de garde
- `FindMatchingPharmacy()` → Trouve une pharmacie OSM correspondante
- `CalculateNameSimilarity()` → Score de similarité (Levenshtein simplifié)

### 3️⃣ **PharmacyHistoryRepository.cs**
```csharp
// Gestion de l'historique
// Enregistre TOUS les changements
// Permet audit, rollback, validation
```

**Méthodes principales :**
- `RecordChangeAsync()` → Enregistre un changement
- `GetHistoryAsync(pharmacyId)` → Récupère l'historique complet
- `CreateConflictAsync()` → Marque un conflit pour révision humaine

### 4️⃣ **WeeklyDataSyncService.cs**
```csharp
// CRON hebdomadaire
// Pipeline complet : OSM → Scraping → Fusion → JSON
// Logs détaillés + résumé final
```

**Méthodes principales :**
- `RunWeeklySyncAsync()` → Exécute le pipeline complet
- `ForceRunAsync()` → Déclenchement manuel

### 5️⃣ **PharmacyHistory.cs** (Domain)
```csharp
// Modèle d'historique
// Champs : old_value, new_value, source, needs_review
```

### 6️⃣ **Migration SQL**
```sql
-- supabase_migration_v2_history_confidence.sql
-- Tables : pharmacy_history, pharmacy_metadata
-- Colonnes ajoutées : confidence_score, data_sources
-- Vues : pharmacies_with_confidence, entries_needing_review
```

---

## 🚀 Installation & Déploiement

### Étape 1 : Migrer la base Supabase

```bash
# Se connecter à Supabase SQL Editor
# Copier-coller le contenu de :
PharmaGoBackend/supabase_migration_v2_history_confidence.sql

# Exécuter
```

### Étape 2 : Installer dépendances .NET

```bash
cd PharmaGoBackend

# Installer HtmlAgilityPack pour le scraping
dotnet add package HtmlAgilityPack
```

### Étape 3 : Configurer Program.cs

Ajouter les nouveaux services dans `Program.cs` :

```csharp
// Services Infrastructure
builder.Services.AddSingleton<PharmaciesDeGardeScraperService>();
builder.Services.AddSingleton<PharmacyDataMergerService>();
builder.Services.AddSingleton<PharmacyHistoryRepository>();

// CRON Services
builder.Services.AddHostedService<WeeklyDataSyncService>();
```

### Étape 4 : Lancer le backend

```bash
dotnet run
```

Le service CRON démarrera automatiquement et :
1. ✅ Exécutera une sync immédiate au démarrage
2. ⏰ Planifiera la prochaine sync pour dimanche 22h UTC

---

## 📊 Score de Confiance

### Calcul (0-100)

| Critère | Points | Description |
|---------|--------|-------------|
| **Base OSM** | +60 | Données GPS fiables |
| **Statut de garde** | +20 | Confirmé par site officiel |
| **Téléphone** | +10 | Numéro renseigné |
| **Historique stable** | +10 | >3 changements enregistrés |

### Affichage Flutter

```dart
if (pharmacy.confidenceScore >= 90) {
  // ✅ Pharmacie vérifiée (badge vert)
} else if (pharmacy.confidenceScore >= 70) {
  // ⚠️ Informations fiables (badge orange)
} else {
  // ℹ️ Informations à confirmer (badge gris)
}
```

---

## 🔍 Monitoring & Validation

### 1️⃣ Consulter les logs

```bash
# Logs du backend
dotnet run

# Rechercher
# ✅ OSM Sync : 514 pharmacie(s)
# ✅ Garde Scraping : 15 pharmacie(s) de garde
# ✅ Fusion : 12 matchés, 3 non-matchés
```

### 2️⃣ Vérifier les conflits

```sql
-- Dans Supabase SQL Editor
SELECT * FROM entries_needing_review;
```

Résultats typiques :
```
| pharmacy_id | change_type       | notes                                   |
|-------------|-------------------|-----------------------------------------|
| conflict_1  | matching_conflict | Conflit pour Pharmacie Centrale Cocody  |
| unmatched_2 | unmatched_guard   | Pharmacie de garde non trouvée dans OSM |
```

### 3️⃣ Validation humaine

```sql
-- Marquer comme validé
UPDATE pharmacy_history
SET is_validated = true,
    validated_at = NOW(),
    validated_by = 'admin@pharmago.ci'
WHERE id = 'conflict_1';
```

---

## 🛠️ Maintenance

### Forcer une synchronisation manuelle

Via API endpoint (à créer) :

```csharp
[HttpPost("api/admin/force-sync")]
public async Task<IActionResult> ForceSync()
{
    var service = HttpContext.RequestServices
        .GetRequiredService<WeeklyDataSyncService>();
    
    await service.ForceRunAsync();
    
    return Ok(new { message = "Sync déclenchée" });
}
```

### Mettre à jour le score de confiance

```sql
-- Recalculer tous les scores
UPDATE pharmacies
SET confidence_score = calculate_confidence_score(id);
```

---

## 📈 Évolutions Futures

### Phase 2 (3-6 mois)
- [ ] **Crowdsourcing** : Les utilisateurs signalent les erreurs
- [ ] **API Validation** : Endpoint pour validation humaine
- [ ] **Dashboard Admin** : Interface pour réviser les conflits

### Phase 3 (6-12 mois)
- [ ] **Partenariat Ordre des Pharmaciens** : Données officielles
- [ ] **Géocodage automatique** : Pour pharmacies non-OSM
- [ ] **ML pour matching** : Améliorer la précision du matching

---

## ⚠️ Limitations & Contraintes

### Scraping pharmacies-de-garde.ci
- ⚠️ **Légalité** : Site public, mais scraping discret recommandé
- ⚠️ **Fragilité** : Structure HTML peut changer
- ⚠️ **Maintenance** : Sélecteurs CSS à adapter si le site change

### Solutions
- ✅ **Fallback** : Extraction depuis texte brut si HTML change
- ✅ **Logs** : Alertes si 0 pharmacies récupérées
- ✅ **Historique** : Permet de voir ce qui fonctionnait avant

---

## 📞 Support

En cas de problème :

1. **Vérifier les logs** : `dotnet run`
2. **Consulter l'historique** : `SELECT * FROM pharmacy_history ORDER BY modified_at DESC LIMIT 10;`
3. **Vérifier Supabase** : Table `pharmacies` doit contenir ~514 entrées

---

## ✅ Checklist Déploiement

- [ ] Migration SQL exécutée
- [ ] HtmlAgilityPack installé
- [ ] Services ajoutés à Program.cs
- [ ] Backend lancé et logs vérifiés
- [ ] Première sync complétée avec succès
- [ ] JSON généré et uploadé dans Supabase Storage
- [ ] Flutter app télécharge le JSON correctement

---

**🎉 Félicitations ! Votre stratégie data est opérationnelle.**

**Prochaine sync automatique** : Dimanche 22h00 UTC
