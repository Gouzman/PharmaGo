-- ========================================
-- POLITIQUE RLS SUPABASE STORAGE
-- Correction du warning RLS
-- ========================================

-- Autoriser le service role à gérer le bucket pharmacy_data
create policy "service_role_can_manage_pharmacy_data"
on storage.objects
for all
to service_role
using (bucket_id = 'pharmacy_data');

-- Permettre la lecture publique du JSON
create policy "public_can_read_pharmacy_json"
on storage.objects
for select
to public
using (bucket_id = 'pharmacy_data' and name = 'pharmacies.json');

-- Résumé :
-- ✅ Service role peut créer/modifier/supprimer
-- ✅ Public peut lire le JSON
-- ❌ Public ne peut pas écrire
