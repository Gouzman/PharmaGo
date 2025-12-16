-- ========================================
-- INDEX SUPABASE POUR PERFORMANCE
-- Optimisation des requêtes pharmacies
-- ========================================

-- Index pour recherche géographique (proximité)
create index if not exists idx_pharmacies_location 
on pharmacies (lat, lng);

-- Index pour pharmacies de garde
create index if not exists idx_pharmacies_is_guard 
on pharmacies (is_guard) 
where is_guard = true;

-- Index pour recherche par commune
create index if not exists idx_pharmacies_commune 
on pharmacies (commune);

-- Index pour recherche par quartier
create index if not exists idx_pharmacies_quartier 
on pharmacies (quartier);

-- Index composite pour recherche garde + commune
create index if not exists idx_pharmacies_guard_commune 
on pharmacies (is_guard, commune) 
where is_guard = true;

-- Index pour tri par date de mise à jour
create index if not exists idx_pharmacies_updated_at 
on pharmacies (updated_at desc);

-- Résumé :
-- ✅ Recherche proximité ultra rapide
-- ✅ Filtre garde optimisé
-- ✅ Recherche par zone performante
-- ✅ Tri chronologique efficace
