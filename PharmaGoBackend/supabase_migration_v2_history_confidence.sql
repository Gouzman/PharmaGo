-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  MIGRATION SUPABASE - STRATÉGIE DATA PHARMAGO v2.0                ║
-- ║  Ajout : Historique + Score de confiance + Métadonnées           ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1️⃣ MISE À JOUR TABLE PHARMACIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ajouter colonnes score de confiance et sources
ALTER TABLE pharmacies 
ADD COLUMN IF NOT EXISTS confidence_score INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS data_sources TEXT DEFAULT 'osm';

-- Créer index pour performance
CREATE INDEX IF NOT EXISTS idx_pharmacies_confidence 
ON pharmacies(confidence_score DESC);

CREATE INDEX IF NOT EXISTS idx_pharmacies_is_guard 
ON pharmacies(is_guard) 
WHERE is_guard = true;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2️⃣ CRÉATION TABLE HISTORIQUE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE IF NOT EXISTS pharmacy_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL,
    change_type TEXT NOT NULL, -- "created", "updated", "guard_status_changed", etc.
    source TEXT NOT NULL, -- "osm", "pharmacies-de-garde.ci", "manual", "user_report"
    
    -- Détails du changement
    field_changed TEXT,
    old_value TEXT,
    new_value TEXT,
    
    -- JSON complet (pour changements complexes)
    old_values JSONB,
    new_values JSONB,
    
    -- Métadonnées
    modified_by TEXT,
    modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    
    -- Validation
    needs_review BOOLEAN DEFAULT false,
    is_validated BOOLEAN DEFAULT false,
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by TEXT,
    
    -- Référence optionnelle vers la pharmacie
    CONSTRAINT fk_pharmacy 
        FOREIGN KEY (pharmacy_id) 
        REFERENCES pharmacies(id) 
        ON DELETE CASCADE
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_history_pharmacy_id 
ON pharmacy_history(pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_history_modified_at 
ON pharmacy_history(modified_at DESC);

CREATE INDEX IF NOT EXISTS idx_history_needs_review 
ON pharmacy_history(needs_review) 
WHERE needs_review = true;

CREATE INDEX IF NOT EXISTS idx_history_source 
ON pharmacy_history(source);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3️⃣ CRÉATION TABLE MÉTADONNÉES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE IF NOT EXISTS pharmacy_metadata (
    pharmacy_id UUID PRIMARY KEY,
    
    -- Score de confiance
    confidence_score INTEGER DEFAULT 60 CHECK (confidence_score >= 0 AND confidence_score <= 100),
    
    -- Sources multiples
    source_count INTEGER DEFAULT 1,
    sources TEXT DEFAULT 'osm', -- Liste séparée par virgules
    
    -- Validation humaine
    is_human_validated BOOLEAN DEFAULT false,
    last_human_validation TIMESTAMP WITH TIME ZONE,
    
    -- Signalements utilisateurs
    user_report_count INTEGER DEFAULT 0,
    
    -- Révision
    needs_review BOOLEAN DEFAULT false,
    review_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Référence vers la pharmacie
    CONSTRAINT fk_pharmacy_metadata 
        FOREIGN KEY (pharmacy_id) 
        REFERENCES pharmacies(id) 
        ON DELETE CASCADE
);

-- Index
CREATE INDEX IF NOT EXISTS idx_metadata_confidence 
ON pharmacy_metadata(confidence_score DESC);

CREATE INDEX IF NOT EXISTS idx_metadata_needs_review 
ON pharmacy_metadata(needs_review) 
WHERE needs_review = true;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4️⃣ TRIGGER POUR AUTO-UPDATE updated_at
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_pharmacies_modtime ON pharmacies;
CREATE TRIGGER update_pharmacies_modtime
    BEFORE UPDATE ON pharmacies
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

DROP TRIGGER IF EXISTS update_metadata_modtime ON pharmacy_metadata;
CREATE TRIGGER update_metadata_modtime
    BEFORE UPDATE ON pharmacy_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5️⃣ VUES UTILES POUR ANALYSE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Vue : Pharmacies avec score de confiance
CREATE OR REPLACE VIEW pharmacies_with_confidence AS
SELECT 
    p.*,
    COALESCE(m.confidence_score, p.confidence_score, 60) as final_confidence_score,
    m.sources,
    m.is_human_validated,
    m.needs_review
FROM pharmacies p
LEFT JOIN pharmacy_metadata m ON p.id = m.pharmacy_id;

-- Vue : Historique récent (30 derniers jours)
CREATE OR REPLACE VIEW recent_history AS
SELECT *
FROM pharmacy_history
WHERE modified_at >= NOW() - INTERVAL '30 days'
ORDER BY modified_at DESC;

-- Vue : Entrées nécessitant révision
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6️⃣ FONCTIONS UTILITAIRES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Fonction : Calculer le score de confiance
CREATE OR REPLACE FUNCTION calculate_confidence_score(p_pharmacy_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_history_count INTEGER;
    v_has_phone BOOLEAN;
    v_is_guard BOOLEAN;
BEGIN
    -- Base OSM : +60
    IF p_pharmacy_id LIKE 'osm_%' THEN
        v_score := v_score + 60;
    END IF;
    
    -- Téléphone renseigné : +10
    SELECT phone IS NOT NULL AND phone != '' INTO v_has_phone
    FROM pharmacies WHERE id = p_pharmacy_id;
    
    IF v_has_phone THEN
        v_score := v_score + 10;
    END IF;
    
    -- Statut de garde : +20
    SELECT is_guard INTO v_is_guard
    FROM pharmacies WHERE id = p_pharmacy_id;
    
    IF v_is_guard THEN
        v_score := v_score + 20;
    END IF;
    
    -- Historique stable (>3 changements) : +10
    SELECT COUNT(*) INTO v_history_count
    FROM pharmacy_history WHERE pharmacy_id = p_pharmacy_id;
    
    IF v_history_count > 3 THEN
        v_score := v_score + 10;
    END IF;
    
    RETURN LEAST(v_score, 100);
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 7️⃣ PERMISSIONS (RLS - ROW LEVEL SECURITY)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Activer RLS
ALTER TABLE pharmacy_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_metadata ENABLE ROW LEVEL SECURITY;

-- Politique : Lecture publique (historique et métadonnées)
CREATE POLICY "Enable read access for all" ON pharmacy_history
    FOR SELECT USING (true);

CREATE POLICY "Enable read access for all" ON pharmacy_metadata
    FOR SELECT USING (true);

-- Politique : Écriture réservée au backend (service role uniquement)
CREATE POLICY "Enable insert for service role only" ON pharmacy_history
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Enable update for service role only" ON pharmacy_history
    FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "Enable insert for service role only" ON pharmacy_metadata
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Enable update for service role only" ON pharmacy_metadata
    FOR UPDATE USING (auth.role() = 'service_role');

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 8️⃣ DONNÉES DE TEST / INITIALISATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Initialiser les métadonnées pour les pharmacies existantes
INSERT INTO pharmacy_metadata (pharmacy_id, confidence_score, sources, source_count)
SELECT 
    id,
    60, -- Score de base OSM
    'osm',
    1
FROM pharmacies
ON CONFLICT (pharmacy_id) DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ✅ MIGRATION TERMINÉE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SELECT 
    '✅ Migration terminée' as status,
    (SELECT COUNT(*) FROM pharmacies) as total_pharmacies,
    (SELECT COUNT(*) FROM pharmacy_metadata) as pharmacies_with_metadata,
    (SELECT COUNT(*) FROM pharmacy_history) as history_entries;
