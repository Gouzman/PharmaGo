using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using PharmaGo.Domain;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Service pour synchroniser les pharmacies OSM avec Supabase
/// </summary>
public class OsmSyncService
{
    private readonly OverpassService _overpassService;
    private readonly SupabaseClientService _supabaseClient;

    public OsmSyncService(OverpassService overpassService, SupabaseClientService supabaseClient)
    {
        _overpassService = overpassService;
        _supabaseClient = supabaseClient;
    }

    /// <summary>
    /// Synchronise les pharmacies depuis OSM vers Supabase
    /// Mode : UPSERT (mise à jour ou insertion)
    /// </summary>
    public async Task<OsmSyncResult> SyncPharmaciesFromOsmAsync()
    {
        try
        {
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine("║     🗺️  SYNCHRONISATION OPENSTREETMAP → SUPABASE    ║");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();

            var startTime = DateTime.UtcNow;

            // 1️⃣ Récupérer les pharmacies depuis OSM
            Console.WriteLine("📍 Étape 1/3 : Récupération depuis OpenStreetMap...");
            var osmPharmacies = await _overpassService.FetchPharmaciesAsync();

            if (osmPharmacies.Count == 0)
            {
                Console.WriteLine("⚠️ Aucune pharmacie récupérée depuis OSM. Abandon.");
                return new OsmSyncResult
                {
                    Success = false,
                    ErrorMessage = "Aucune pharmacie trouvée sur OpenStreetMap",
                    FetchedCount = 0,
                    SyncedCount = 0,
                    Duration = DateTime.UtcNow - startTime
                };
            }

            Console.WriteLine($"✅ {osmPharmacies.Count} pharmacie(s) récupérée(s) depuis OSM");
            Console.WriteLine();

            // 2️⃣ Récupérer les pharmacies existantes dans Supabase
            Console.WriteLine("📍 Étape 2/3 : Récupération des données existantes Supabase...");
            var existingPharmacies = await _supabaseClient.GetPharmaciesAsync();
            Console.WriteLine($"✅ {existingPharmacies.Count} pharmacie(s) existante(s) dans Supabase");
            
            // 🗑️ Nettoyer les anciennes pharmacies non-OSM (données de test)
            var nonOsmPharmacies = existingPharmacies.Where(p => !p.Id.StartsWith("osm_")).ToList();
            if (nonOsmPharmacies.Count > 0)
            {
                Console.WriteLine($"🗑️ Suppression de {nonOsmPharmacies.Count} ancienne(s) pharmacie(s) non-OSM...");
                foreach (var oldPharmacy in nonOsmPharmacies)
                {
                    try
                    {
                        await _supabaseClient.DeletePharmacyAsync(oldPharmacy.Id);
                        Console.WriteLine($"  ❌ Supprimé: {oldPharmacy.Name} (ID: {oldPharmacy.Id})");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"  ⚠️ Erreur suppression {oldPharmacy.Id}: {ex.Message}");
                    }
                }
                Console.WriteLine($"✅ {nonOsmPharmacies.Count} ancienne(s) pharmacie(s) supprimée(s)");
                
                // Recharger la liste après suppression
                existingPharmacies = await _supabaseClient.GetPharmaciesAsync();
            }
            Console.WriteLine();

            // 3️⃣ Upsert dans Supabase
            Console.WriteLine("📍 Étape 3/3 : Synchronisation avec Supabase...");
            var syncedCount = await UpsertPharmaciesAsync(osmPharmacies, existingPharmacies);

            var duration = DateTime.UtcNow - startTime;

            Console.WriteLine();
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine($"║  ✅ SYNCHRONISATION TERMINÉE EN {duration.TotalSeconds:F1}s");
            Console.WriteLine($"║  📊 {osmPharmacies.Count} récupérées | {syncedCount} synchronisées");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();

            return new OsmSyncResult
            {
                Success = true,
                FetchedCount = osmPharmacies.Count,
                SyncedCount = syncedCount,
                Duration = duration
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la synchronisation OSM: {ex.Message}");
            return new OsmSyncResult
            {
                Success = false,
                ErrorMessage = ex.Message,
                FetchedCount = 0,
                SyncedCount = 0
            };
        }
    }

    /// <summary>
    /// Effectue l'upsert (update or insert) des pharmacies dans Supabase
    /// </summary>
    private async Task<int> UpsertPharmaciesAsync(
        List<Pharmacy> osmPharmacies,
        List<Pharmacy> existingPharmacies)
    {
        var syncedCount = 0;
        var existingIds = new HashSet<string>(existingPharmacies.Select(p => p.Id));

        foreach (var pharmacy in osmPharmacies)
        {
            try
            {
                // Vérifier si la pharmacie existe déjà
                var exists = existingIds.Contains(pharmacy.Id);

                if (exists)
                {
                    // Mise à jour
                    await _supabaseClient.UpdatePharmacyAsync(pharmacy);
                    Console.WriteLine($"  🔄 Mise à jour: {pharmacy.Name}");
                }
                else
                {
                    // Insertion
                    await _supabaseClient.InsertPharmacyAsync(pharmacy);
                    Console.WriteLine($"  ➕ Ajout: {pharmacy.Name}");
                }

                syncedCount++;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  ⚠️ Erreur pour {pharmacy.Name}: {ex.Message}");
            }
        }

        return syncedCount;
    }

    /// <summary>
    /// Récupère la liste des pharmacies OSM (pour fusion)
    /// </summary>
    public async Task<List<Pharmacy>> GetOsmPharmaciesAsync()
    {
        return await _supabaseClient.GetPharmaciesAsync();
    }
}

/// <summary>
/// Résultat de la synchronisation OSM
/// </summary>
public class OsmSyncResult
{
    public bool Success { get; set; }
    public int FetchedCount { get; set; }
    public int SyncedCount { get; set; }
    public string? ErrorMessage { get; set; }
    public TimeSpan Duration { get; set; }
}
