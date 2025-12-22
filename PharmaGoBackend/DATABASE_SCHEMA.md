# 🗄️ SCHÉMA BASE DE DONNÉES - PHARMAGO V2.0

## 📊 Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE POSTGRESQL                      │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   pharmacies     │◄──────│ pharmacy_history │       │ pharmacy_metadata│
│  (table prin.)   │  1:N  │  (audit trail)   │  1:1  │  (qualité)       │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │
         │ 1:N
         ▼
┌──────────────────┐
│  guard_schedule  │
│  (périodes)      │
└──────────────────┘
```

---

## 📋 TABLE : `pharmacies` (Principale)

### Structure

| Colonne | Type | Description | Exemple |
|---------|------|-------------|---------|
| `id` | TEXT (PK) | ID unique | `osm_node_123456` |
| `name` | TEXT | Nom de la pharmacie | `Pharmacie Centrale Cocody` |
| `lat` | DOUBLE | Latitude GPS | `5.345317` |
| `lng` | DOUBLE | Longitude GPS | `-4.024429` |
| `address` | TEXT | Adresse complète | `Bd des Martyrs, Marcory` |
| `phone` | TEXT | Téléphone | `07 09 02 73 56` |
| `commune` | TEXT | Commune | `Cocody` |
| `quartier` | TEXT | Quartier | `Riviera Palmeraie` |
| `assurances` | TEXT[] | Liste assurances | `["MUGEFCI", "INPS"]` |
| `is_guard` | BOOLEAN | Est de garde | `true` |
| `confidence_score` ⭐ | INTEGER | Score 0-100 | `92` |
| `data_sources` ⭐ | TEXT | Sources séparées par `,` | `osm,pharmacies-de-garde.ci` |
| `updated_at` | TIMESTAMP | Dernière MAJ | `2025-12-19 22:00:00Z` |
| `open_hours` | JSONB | Horaires (optionnel) | `{"open":"08:00","close":"20:00"}` |

⭐ = Nouvelle colonne V2.0

### Contraintes

```sql
PRIMARY KEY (id)
CHECK (confidence_score >= 0 AND confidence_score <= 100)
CHECK (lat BETWEEN -90 AND 90)
CHECK (lng BETWEEN -180 AND 180)
```

### Index

```sql
CREATE INDEX idx_pharmacies_guard ON pharmacies(is_guard) WHERE is_guard = true;
CREATE INDEX idx_pharmacies_commune ON pharmacies(commune);
CREATE INDEX idx_pharmacies_confidence ON pharmacies(confidence_score DESC);
CREATE INDEX idx_pharmacies_location ON pharmacies USING GIST (ll_to_earth(lat, lng));
```

---

## 📜 TABLE : `pharmacy_history` (Audit Trail)

### Structure

| Colonne | Type | Description | Exemple |
|---------|------|-------------|---------|
| `id` | UUID (PK) | ID unique auto-généré | `a1b2c3d4-...` |
| `pharmacy_id` | TEXT (FK) | Référence pharmacie | `osm_node_123456` |
| `change_type` | TEXT | Type de changement | `guard_status_changed` |
| `source` | TEXT | Source du changement | `pharmacies-de-garde.ci` |
| `field_changed` | TEXT | Champ modifié | `is_guard` |
| `old_value` | TEXT | Ancienne valeur | `false` |
| `new_value` | TEXT | Nouvelle valeur | `true` |
| `old_values` | JSONB | JSON complet avant | `{...}` |
| `new_values` | JSONB | JSON complet après | `{...}` |
| `modified_by` | TEXT | Auteur (optionnel) | `admin@pharmago.ci` |
| `modified_at` | TIMESTAMP | Date modification | `2025-12-19 22:05:00Z` |
| `notes` | TEXT | Notes/raison | `Garde du 18/12 au 24/12` |
| `needs_review` | BOOLEAN | Nécessite révision | `false` |
| `is_validated` | BOOLEAN | Validé par humain | `false` |
| `validated_at` | TIMESTAMP | Date validation | `null` |
| `validated_by` | TEXT | Validateur | `null` |

### Types de Changements

```sql
change_type IN (
  'created',              -- Nouvelle pharmacie
  'updated',              -- Mise à jour générale
  'guard_status_changed', -- Statut de garde modifié
  'matched',              -- Matché avec source externe
  'matching_conflict',    -- Conflit de matching
  'unmatched_guard',      -- Garde non trouvée dans OSM
  'deleted'               -- Suppression
)
```

### Sources

```sql
source IN (
  'osm',                     -- OpenStreetMap
  'pharmacies-de-garde.ci',  -- Site officiel
  'manual',                  -- Validation humaine
  'user_report',             -- Signalement utilisateur
  'merge_service'            -- Service de fusion
)
```

### Index

```sql
CREATE INDEX idx_history_pharmacy ON pharmacy_history(pharmacy_id);
CREATE INDEX idx_history_date ON pharmacy_history(modified_at DESC);
CREATE INDEX idx_history_review ON pharmacy_history(needs_review) WHERE needs_review = true;
CREATE INDEX idx_history_source ON pharmacy_history(source);
```

---

## 🏷️ TABLE : `pharmacy_metadata` (Qualité)

### Structure

| Colonne | Type | Description | Exemple |
|---------|------|-------------|---------|
| `pharmacy_id` | TEXT (PK, FK) | Référence pharmacie | `osm_node_123456` |
| `confidence_score` | INTEGER | Score 0-100 | `92` |
| `source_count` | INTEGER | Nombre de sources | `2` |
| `sources` | TEXT | Liste sources | `osm,pharmacies-de-garde.ci` |
| `is_human_validated` | BOOLEAN | Validé humain | `false` |
| `last_human_validation` | TIMESTAMP | Date validation | `null` |
| `user_report_count` | INTEGER | Nb signalements | `0` |
| `needs_review` | BOOLEAN | À réviser | `false` |
| `review_reason` | TEXT | Raison révision | `null` |
| `created_at` | TIMESTAMP | Création | `2025-12-19 22:00:00Z` |
| `updated_at` | TIMESTAMP | Dernière MAJ | `2025-12-19 22:00:00Z` |

### Contraintes

```sql
PRIMARY KEY (pharmacy_id)
FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE
CHECK (confidence_score >= 0 AND confidence_score <= 100)
CHECK (source_count >= 1)
```

### Index

```sql
CREATE INDEX idx_metadata_confidence ON pharmacy_metadata(confidence_score DESC);
CREATE INDEX idx_metadata_review ON pharmacy_metadata(needs_review) WHERE needs_review = true;
```

---

## 📅 TABLE : `guard_schedule` (Plannings)

### Structure

| Colonne | Type | Description | Exemple |
|---------|------|-------------|---------|
| `id` | TEXT (PK) | ID unique | `guard_2025_12_19` |
| `pharmacy_id` | TEXT (FK) | Référence pharmacie | `osm_node_123456` |
| `guard_date` | DATE | Date de garde | `2025-12-19` |
| `start_time` | TIME | Heure début | `08:00` |
| `end_time` | TIME | Heure fin | `20:00` |
| `is_active` | BOOLEAN | Actif | `true` |
| `created_at` | TIMESTAMP | Création | `2025-12-19 22:00:00Z` |

### Contraintes

```sql
PRIMARY KEY (id)
FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE
```

### Index

```sql
CREATE INDEX idx_guard_date ON guard_schedule(guard_date DESC);
CREATE INDEX idx_guard_active ON guard_schedule(is_active) WHERE is_active = true;
CREATE INDEX idx_guard_pharmacy ON guard_schedule(pharmacy_id);
```

---

## 🔍 VUES SQL

### Vue : `pharmacies_with_confidence`

```sql
CREATE OR REPLACE VIEW pharmacies_with_confidence AS
SELECT 
    p.*,
    COALESCE(m.confidence_score, p.confidence_score, 60) as final_confidence_score,
    m.sources,
    m.is_human_validated,
    m.needs_review
FROM pharmacies p
LEFT JOIN pharmacy_metadata m ON p.id = m.pharmacy_id;
```

**Usage** :
```sql
SELECT * FROM pharmacies_with_confidence 
WHERE final_confidence_score >= 80
ORDER BY final_confidence_score DESC;
```

---

### Vue : `recent_history`

```sql
CREATE OR REPLACE VIEW recent_history AS
SELECT *
FROM pharmacy_history
WHERE modified_at >= NOW() - INTERVAL '30 days'
ORDER BY modified_at DESC;
```

**Usage** :
```sql
SELECT * FROM recent_history 
WHERE change_type = 'guard_status_changed';
```

---

### Vue : `entries_needing_review`

```sql
CREATE OR REPLACE VIEW entries_needing_review AS
SELECT 
    h.id,
    h.pharmacy_id,
    h.change_type,
    h.notes,
    h.modified_at,
    p.name as pharmacy_name
FROM pharmacy_history h
LEFT JOIN pharmacies p ON h.pharmacy_id = p.id
WHERE h.needs_review = true AND h.is_validated = false
ORDER BY h.modified_at DESC;
```

**Usage** :
```sql
SELECT * FROM entries_needing_review;
```

---

## 📊 RELATIONS

```
pharmacies (1) ────────── (N) pharmacy_history
    │                           │
    │                           └─ FK: pharmacy_id
    │
    ├────────── (1:1) ────────── pharmacy_metadata
    │                             └─ FK: pharmacy_id
    │
    └────────── (1:N) ────────── guard_schedule
                                  └─ FK: pharmacy_id
```

---

## 🔐 ROW LEVEL SECURITY (RLS)

### Lecture Publique

```sql
-- Tout le monde peut lire les pharmacies
CREATE POLICY "Enable read for all" ON pharmacies
    FOR SELECT USING (true);

-- Tout le monde peut lire l'historique
CREATE POLICY "Enable read for all" ON pharmacy_history
    FOR SELECT USING (true);

-- Tout le monde peut lire les métadonnées
CREATE POLICY "Enable read for all" ON pharmacy_metadata
    FOR SELECT USING (true);
```

### Écriture Restreinte (Backend uniquement)

```sql
-- Seul le service role peut écrire
CREATE POLICY "Service role only" ON pharmacy_history
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role only" ON pharmacy_history
    FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "Service role only" ON pharmacy_metadata
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role only" ON pharmacy_metadata
    FOR UPDATE USING (auth.role() = 'service_role');
```

---

## 🎯 REQUÊTES UTILES

### Top 10 pharmacies les plus fiables

```sql
SELECT name, commune, confidence_score, data_sources
FROM pharmacies
ORDER BY confidence_score DESC
LIMIT 10;
```

### Pharmacies de garde actives

```sql
SELECT p.name, p.commune, p.phone, p.confidence_score
FROM pharmacies p
WHERE p.is_guard = true
ORDER BY p.confidence_score DESC;
```

### Historique d'une pharmacie

```sql
SELECT change_type, field_changed, old_value, new_value, modified_at, source
FROM pharmacy_history
WHERE pharmacy_id = 'osm_node_123456'
ORDER BY modified_at DESC;
```

### Conflits à réviser

```sql
SELECT * FROM entries_needing_review;
```

### Statistiques globales

```sql
SELECT 
    COUNT(*) as total_pharmacies,
    COUNT(*) FILTER (WHERE is_guard = true) as pharmacies_de_garde,
    AVG(confidence_score)::int as avg_confidence,
    COUNT(DISTINCT data_sources) as nb_sources
FROM pharmacies;
```

---

## 📈 ÉVOLUTIONS FUTURES

### Phase 2 : Signalements Utilisateurs

```sql
CREATE TABLE user_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id TEXT REFERENCES pharmacies(id),
    user_id TEXT,
    report_type TEXT, -- 'wrong_hours', 'wrong_phone', 'closed', etc.
    reported_value TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    is_validated BOOLEAN DEFAULT false
);
```

### Phase 3 : Photos

```sql
ALTER TABLE pharmacies 
ADD COLUMN photos TEXT[] DEFAULT '{}';
```

### Phase 4 : Avis Clients

```sql
CREATE TABLE pharmacy_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id TEXT REFERENCES pharmacies(id),
    user_id TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

**Ce schéma est conçu pour** :
- ✅ Scalabilité (millions de pharmacies potentiellement)
- ✅ Traçabilité (audit complet)
- ✅ Qualité (score de confiance)
- ✅ Flexibilité (évolutions futures faciles)
