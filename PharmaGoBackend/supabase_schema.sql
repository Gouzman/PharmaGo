-- ===============================================================
-- SCRIPT SQL POUR SUPABASE - PharmaGo
-- ===============================================================
-- Ce script crée toutes les tables nécessaires pour le backend
-- ===============================================================

-- Table des pharmacies
CREATE TABLE IF NOT EXISTS pharmacies (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    address TEXT,
    phone TEXT,
    commune TEXT,
    quartier TEXT,
    assurances TEXT[] DEFAULT '{}',
    is_guard BOOLEAN DEFAULT false,
    open_hours JSONB,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour les recherches fréquentes
CREATE INDEX IF NOT EXISTS idx_pharmacies_commune ON pharmacies(commune);
CREATE INDEX IF NOT EXISTS idx_pharmacies_is_guard ON pharmacies(is_guard);
CREATE INDEX IF NOT EXISTS idx_pharmacies_location ON pharmacies(lat, lng);

-- Table des plannings de garde
CREATE TABLE IF NOT EXISTS guard_schedules (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    pharmacy_id TEXT NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    start TIMESTAMP WITH TIME ZONE NOT NULL,
    end TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour les requêtes de garde
CREATE INDEX IF NOT EXISTS idx_guard_schedules_pharmacy ON guard_schedules(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_guard_schedules_dates ON guard_schedules(start, end);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour updated_at sur pharmacies
DROP TRIGGER IF EXISTS update_pharmacies_updated_at ON pharmacies;
CREATE TRIGGER update_pharmacies_updated_at
    BEFORE UPDATE ON pharmacies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===============================================================
-- DONNÉES DE TEST (optionnel)
-- ===============================================================

-- Insertion de quelques pharmacies de test
INSERT INTO pharmacies (id, name, lat, lng, address, commune, quartier, phone, assurances, open_hours) VALUES
('ph_001', 'Pharmacie Centrale', 33.5731, -7.5898, '123 Rue Mohammed V', 'Casablanca', 'Maarif', '+212522123456', ARRAY['CNSS', 'CNOPS', 'RMA'], '{"open": "08:00", "close": "20:00"}'),
('ph_002', 'Pharmacie Al Amal', 33.5825, -7.6032, '456 Boulevard Zerktouni', 'Casablanca', 'Gauthier', '+212522234567', ARRAY['CNSS', 'CNOPS'], '{"open": "08:30", "close": "21:00"}'),
('ph_003', 'Pharmacie du Quartier', 33.5891, -7.6115, '789 Avenue Hassan II', 'Casablanca', 'Centre Ville', '+212522345678', ARRAY['CNSS', 'RMA', 'Saham'], '{"open": "08:00", "close": "22:00"}')
ON CONFLICT (id) DO NOTHING;

-- Insertion d'un planning de garde pour aujourd'hui
INSERT INTO guard_schedules (pharmacy_id, start, end)
VALUES 
('ph_001', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day')
ON CONFLICT DO NOTHING;

-- ===============================================================
-- POLICIES RLS (Row Level Security) - OPTIONNEL
-- ===============================================================
-- Activer RLS si nécessaire pour la sécurité

-- ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_schedules ENABLE ROW LEVEL SECURITY;

-- Policy pour lecture publique des pharmacies
-- CREATE POLICY "Pharmacies are viewable by everyone"
--     ON pharmacies FOR SELECT
--     USING (true);

-- Policy pour lecture publique des gardes
-- CREATE POLICY "Guard schedules are viewable by everyone"
--     ON guard_schedules FOR SELECT
--     USING (true);

-- ===============================================================
-- VUES UTILES
-- ===============================================================

-- Vue des pharmacies de garde actives
CREATE OR REPLACE VIEW active_guard_pharmacies AS
SELECT 
    p.*,
    gs.start as guard_start,
    gs.end as guard_end
FROM pharmacies p
INNER JOIN guard_schedules gs ON p.id = gs.pharmacy_id
WHERE gs.start <= NOW() AND gs.end >= NOW();

-- ===============================================================
-- FIN DU SCRIPT
-- ===============================================================
