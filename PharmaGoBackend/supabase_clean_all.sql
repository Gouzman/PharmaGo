-- ================================================================
-- NETTOYAGE COMPLET DE LA TABLE PHARMACIES
-- ================================================================
-- ⚠️ ATTENTION: Cette commande supprime TOUTES les pharmacies
-- À exécuter UNE SEULE FOIS avant la première synchronisation OSM
-- ================================================================

-- Supprimer toutes les pharmacies existantes
DELETE FROM pharmacies;

-- Réinitialiser les compteurs (optionnel)
-- Si vous avez une séquence pour les IDs, décommentez la ligne suivante:
-- ALTER SEQUENCE pharmacies_id_seq RESTART WITH 1;

-- Vérification
SELECT COUNT(*) AS remaining_pharmacies FROM pharmacies;
-- Résultat attendu: 0

-- ================================================================
-- INSTRUCTIONS:
-- 1. Copier ce script
-- 2. Aller dans Supabase Dashboard > SQL Editor
-- 3. Coller et exécuter
-- 4. Relancer la synchronisation OSM via: 
--    curl -X POST http://localhost:5000/api/pharmacies/sync/osm
-- ================================================================
