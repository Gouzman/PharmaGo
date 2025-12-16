-- ═══════════════════════════════════════════════════════════════
-- 🏥 PHARMAGO - SCHÉMA SUPABASE COMPLET
-- ═══════════════════════════════════════════════════════════════
-- Ce fichier contient tout le schéma SQL nécessaire pour PharmaGo
-- Exécutez-le dans l'éditeur SQL de Supabase
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 1. TABLE : pharmacies
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pharmacies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    address TEXT,
    commune TEXT,
    quartier TEXT,
    phone TEXT,
    assurances TEXT[], -- Array de strings
    open_hours JSONB, -- {"open": "08:00", "close": "20:00"}
    is_guard BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_pharmacies_commune ON pharmacies(commune);
CREATE INDEX IF NOT EXISTS idx_pharmacies_is_guard ON pharmacies(is_guard);
CREATE INDEX IF NOT EXISTS idx_pharmacies_location ON pharmacies(lat, lng);

-- ───────────────────────────────────────────────────────────────
-- 2. TABLE : guard_schedule (planning des gardes)
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS guard_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID REFERENCES pharmacies(id) ON DELETE CASCADE,
    guard_date DATE NOT NULL,
    start_time TIME DEFAULT '00:00',
    end_time TIME DEFAULT '23:59',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte : une pharmacie ne peut pas avoir 2 gardes le même jour
    UNIQUE(pharmacy_id, guard_date)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_guard_date ON guard_schedule(guard_date);
CREATE INDEX IF NOT EXISTS idx_guard_active ON guard_schedule(is_active);

-- ───────────────────────────────────────────────────────────────
-- 3. FONCTION : Mettre à jour updated_at automatiquement
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur pharmacies
DROP TRIGGER IF EXISTS update_pharmacies_updated_at ON pharmacies;
CREATE TRIGGER update_pharmacies_updated_at
    BEFORE UPDATE ON pharmacies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ───────────────────────────────────────────────────────────────
-- 4. FONCTION : Synchroniser is_guard avec guard_schedule
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION sync_guard_status()
RETURNS void AS $$
BEGIN
    -- Réinitialiser tous les is_guard à false
    UPDATE pharmacies SET is_guard = false;
    
    -- Mettre à jour les pharmacies de garde pour aujourd'hui
    UPDATE pharmacies p
    SET is_guard = true
    FROM guard_schedule gs
    WHERE p.id = gs.pharmacy_id
      AND gs.guard_date = CURRENT_DATE
      AND gs.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- ───────────────────────────────────────────────────────────────
-- 5. BUCKET STORAGE : pharmacy_data
-- ───────────────────────────────────────────────────────────────
-- ⚠️ IMPORTANT : Créer ce bucket manuellement dans Supabase UI
-- Nom : pharmacy_data
-- Type : PUBLIC
-- Fichier principal : pharmacies.json

-- Politique RLS pour le bucket (lecture publique)
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('pharmacy_data', 'pharmacy_data', true);

-- ───────────────────────────────────────────────────────────────
-- 6. RLS (Row Level Security) - Politique d'accès
-- ───────────────────────────────────────────────────────────────

-- Activer RLS
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE guard_schedule ENABLE ROW LEVEL SECURITY;

-- Politique : Lecture publique des pharmacies
DROP POLICY IF EXISTS "Lecture publique pharmacies" ON pharmacies;
CREATE POLICY "Lecture publique pharmacies"
    ON pharmacies FOR SELECT
    USING (true);

-- Politique : Lecture publique des gardes
DROP POLICY IF EXISTS "Lecture publique gardes" ON guard_schedule;
CREATE POLICY "Lecture publique gardes"
    ON guard_schedule FOR SELECT
    USING (true);

-- Politique : Écriture réservée (service_role uniquement)
-- Les insertions/modifications se font via le backend .NET

-- ───────────────────────────────────────────────────────────────
-- 7. DONNÉES DE TEST (Abidjan, Côte d'Ivoire)
-- ───────────────────────────────────────────────────────────────
INSERT INTO pharmacies (name, lat, lng, address, commune, quartier, phone, assurances, open_hours, is_guard)
VALUES 
    ('Pharmacie St Gabriel', 5.345317, -4.024429, 'Bd des Martyrs', 'Marcory', 'Zone 4', '07 09 02 73 56', 
     ARRAY['MUGEFCI', 'INPS', 'AXA'], 
     '{"open": "08:00", "close": "20:00"}'::jsonb, 
     true),
    
    ('Pharmacie de la Riviera', 5.355317, -4.014429, 'Avenue 18, Riviera Palmeraie', 'Cocody', 'Riviera Palmeraie', '27 21 23 45 67',
     ARRAY['MUGEFCI', 'CNPS'],
     '{"open": "07:00", "close": "22:00"}'::jsonb,
     false),
    
    ('Pharmacie Principale d''Abobo', 5.416891, -4.018132, 'Autoroute d''Abobo, Aboboté', 'Abobo', 'Aboboté', '42 52 77 79',
     ARRAY['MUGEFCI', 'INPS', 'AXA', 'SAHAM'],
     '{"open": "08:00", "close": "20:00"}'::jsonb,
     false),
    
    ('Pharmacie du Plateau', 5.324912, -4.023582, 'Rue du Commerce', 'Plateau', 'Centre des Affaires', '27 20 21 22 23',
     ARRAY['MUGEFCI', 'CNPS', 'AXA'],
     '{"open": "08:00", "close": "21:00"}'::jsonb,
     true),
    
    ('Pharmacie Yopougon', 5.335789, -4.087654, 'Rue Princesse, Yopougon Sideci', 'Yopougon', 'Sideci', '05 06 07 08 09',
     ARRAY['MUGEFCI', 'INPS'],
     '{"open": "08:00", "close": "19:00"}'::jsonb,
     false),
    
    ('Pharmacie Treichville', 5.302156, -4.012389, 'Avenue 7', 'Treichville', 'Zone 3', '27 21 34 56 78',
     ARRAY['MUGEFCI', 'CNPS', 'AXA', 'SAHAM'],
     '{"open": "07:30", "close": "21:30"}'::jsonb,
     false),
    
    ('Pharmacie Adjamé', 5.361234, -4.030567, 'Boulevard Nangui Abrogoua', 'Adjamé', 'Liberté', '27 20 32 45 67',
     ARRAY['MUGEFCI', 'INPS', 'AXA'],
     '{"open": "08:00", "close": "20:00"}'::jsonb,
     false),
    
    ('Pharmacie Cocody Angré', 5.383456, -3.987234, 'Rue des Jardins', 'Cocody', 'Angré 8ème Tranche', '27 22 45 67 89',
     ARRAY['MUGEFCI', 'CNPS', 'AXA', 'SAHAM', 'ALLIANZ'],
     '{"open": "07:00", "close": "22:00"}'::jsonb,
     true)
ON CONFLICT DO NOTHING;

-- Planning de garde pour les 7 prochains jours
INSERT INTO guard_schedule (pharmacy_id, guard_date, is_active)
SELECT 
    id,
    CURRENT_DATE + (gs.day_offset || ' days')::interval,
    true
FROM pharmacies
CROSS JOIN (
    VALUES (0), (1), (2), (3), (4), (5), (6)
) AS gs(day_offset)
WHERE is_guard = true
ON CONFLICT (pharmacy_id, guard_date) DO NOTHING;

-- ───────────────────────────────────────────────────────────────
-- 8. VUES UTILES
-- ───────────────────────────────────────────────────────────────

-- Vue : Pharmacies de garde aujourd'hui
CREATE OR REPLACE VIEW pharmacies_garde_today AS
SELECT 
    p.*,
    gs.guard_date,
    gs.start_time,
    gs.end_time
FROM pharmacies p
JOIN guard_schedule gs ON p.id = gs.pharmacy_id
WHERE gs.guard_date = CURRENT_DATE
  AND gs.is_active = true;

-- Vue : Statistiques par commune
CREATE OR REPLACE VIEW stats_by_commune AS
SELECT 
    commune,
    COUNT(*) as total_pharmacies,
    COUNT(*) FILTER (WHERE is_guard) as pharmacies_garde,
    array_agg(DISTINCT a) as assurances_disponibles
FROM pharmacies
CROSS JOIN LATERAL unnest(assurances) as a
GROUP BY commune
ORDER BY total_pharmacies DESC;

-- ───────────────────────────────────────────────────────────────
-- 9. FONCTION API : Obtenir les pharmacies proches
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_nearby_pharmacies(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    address TEXT,
    commune TEXT,
    quartier TEXT,
    phone TEXT,
    assurances TEXT[],
    open_hours JSONB,
    is_guard BOOLEAN,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.lat,
        p.lng,
        p.address,
        p.commune,
        p.quartier,
        p.phone,
        p.assurances,
        p.open_hours,
        p.is_guard,
        -- Formule de Haversine pour calculer la distance
        (
            6371 * acos(
                cos(radians(user_lat)) * 
                cos(radians(p.lat)) * 
                cos(radians(p.lng) - radians(user_lng)) + 
                sin(radians(user_lat)) * 
                sin(radians(p.lat))
            )
        ) as distance_km
    FROM pharmacies p
    WHERE (
        6371 * acos(
            cos(radians(user_lat)) * 
            cos(radians(p.lat)) * 
            cos(radians(p.lng) - radians(user_lng)) + 
            sin(radians(user_lat)) * 
            sin(radians(p.lat))
        )
    ) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ───────────────────────────────────────────────────────────────
-- 10. REALTIME (Publication en temps réel)
-- ───────────────────────────────────────────────────────────────
-- Activer Realtime sur la table pharmacies pour les updates is_guard
-- ⚠️ À configurer dans Supabase UI : Database → Replication

-- ═══════════════════════════════════════════════════════════════
-- ✅ SCHÉMA SUPABASE COMPLET INSTALLÉ
-- ═══════════════════════════════════════════════════════════════

-- Vérifications
SELECT 'Tables créées' as status, count(*) as count FROM information_schema.tables WHERE table_schema = 'public';
SELECT 'Pharmacies insérées' as status, count(*) as count FROM pharmacies;
SELECT 'Gardes planifiées' as status, count(*) as count FROM guard_schedule;

-- Test de la fonction
SELECT * FROM get_nearby_pharmacies(5.345317, -4.024429, 10.0);

-- ═══════════════════════════════════════════════════════════════
-- 📝 NOTES D'UTILISATION
-- ═══════════════════════════════════════════════════════════════
-- 
-- 1. Créer le bucket 'pharmacy_data' manuellement dans Supabase UI
-- 2. Le rendre PUBLIC pour que le JSON soit accessible sans auth
-- 3. Le backend .NET uploade automatiquement pharmacies.json
-- 4. Flutter télécharge le JSON depuis l'URL publique
-- 5. Les CRON backend mettent à jour automatiquement
--
-- URL publique du JSON :
-- https://[votre-projet].supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json
--
-- ═══════════════════════════════════════════════════════════════
