using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using PharmaGo.Domain;
using PharmaGo.Infrastructure;

namespace PharmaGo.Application;

/// <summary>
/// Service de synchronisation et génération du JSON des pharmacies
/// </summary>
public class PharmacySyncService
{
    private readonly SupabaseClientService _supabaseClient;
    private readonly PharmacyRepository _repository;
    private readonly OsmSyncService _osmSyncService;
    private readonly PharmaciesDeGardeScraperService _scraperService;
    private readonly PharmacyDataMergerService _mergerService;

    public PharmacySyncService(
        SupabaseClientService supabaseClient, 
        PharmacyRepository repository,
        OsmSyncService osmSyncService,
        PharmaciesDeGardeScraperService scraperService,
        PharmacyDataMergerService mergerService)
    {
        _supabaseClient = supabaseClient;
        _repository = repository;
        _osmSyncService = osmSyncService;
        _scraperService = scraperService;
        _mergerService = mergerService;
    }

    /// <summary>
    /// Génère le fichier JSON versionné contenant toutes les pharmacies
    /// </summary>
    public async Task<string> GeneratePharmaciesJsonAsync()
    {
        try
        {
            Console.WriteLine("🔄 Génération du JSON des pharmacies...");

            // Récupérer toutes les pharmacies
            var pharmacies = await _repository.GetAllAsync();

            // Créer la structure JSON versionnée
            var pharmacyData = new PharmacyJsonData
            {
                Version = DateTime.UtcNow.Ticks,
                GeneratedAt = DateTime.UtcNow,
                Pharmacies = pharmacies.Select(p => new PharmacyJsonDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Lat = p.Lat,
                    Lng = p.Lng,
                    Address = p.Address,
                    Commune = p.Commune,
                    Quartier = p.Quartier,
                    Phone = p.Phone,
                    Assurances = p.Assurances,
                    OpenHours = p.OpenHours != null ? new OpenHoursDto
                    {
                        Open = p.OpenHours.Open,
                        Close = p.OpenHours.Close
                    } : null,
                    IsGuard = p.IsGuard,
                    UpdatedAt = p.UpdatedAt
                }).ToList()
            };

            // Serialiser en JSON avec formatage
            var options = new JsonSerializerOptions
            {
                WriteIndented = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
            };

            var json = JsonSerializer.Serialize(pharmacyData, options);

            Console.WriteLine($"✅ JSON généré avec succès - {pharmacies.Count} pharmacie(s)");
            return json;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la génération du JSON: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Synchronise les pharmacies de garde et génère le JSON
    /// </summary>
    public async Task<string> SyncGuardPharmaciesAsync()
    {
        try
        {
            Console.WriteLine("🔄 Synchronisation des pharmacies de garde...");

            // Récupérer les plannings de garde actifs
            var guardSchedules = await _supabaseClient.GetActiveGuardSchedulesAsync();
            var guardPharmacyIds = guardSchedules.Select(g => g.PharmacyId).ToList();

            // Mettre à jour le statut de garde dans Supabase
            await _supabaseClient.UpdateGuardStatusAsync(guardPharmacyIds);

            Console.WriteLine($"✅ Synchronisation terminée - {guardPharmacyIds.Count} pharmacie(s) de garde");

            // Régénérer le JSON
            return await GeneratePharmaciesJsonAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la synchronisation: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Upload le JSON dans Supabase Storage
    /// </summary>
    public async Task<string> UploadJsonToStorageAsync()
    {
        try
        {
            Console.WriteLine("📤 Upload du JSON vers Supabase Storage...");

            // Générer le JSON
            var json = await GeneratePharmaciesJsonAsync();

            // Vérifier que le bucket existe
            await _supabaseClient.EnsureBucketExistsAsync();

            // Upload vers Supabase
            var publicUrl = await _supabaseClient.UploadJsonAsync(json);

            Console.WriteLine($"✅ Upload terminé: {publicUrl}");
            return publicUrl;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de l'upload: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Synchronisation complète : OSM → Supabase → garde → JSON → upload
    /// </summary>
    public async Task<PharmacySyncResult> FullSyncAsync()
    {
        try
        {
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine("║      🚀 SYNCHRONISATION COMPLÈTE (OSM + SCRAPING)    ║");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();
            
            var startTime = DateTime.UtcNow;

            // 1️⃣ Synchroniser depuis OSM vers Supabase
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Console.WriteLine("📍 PHASE 1/4 : Synchronisation OpenStreetMap → Supabase");
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            var osmResult = await _osmSyncService.SyncPharmaciesFromOsmAsync();

            if (!osmResult.Success)
            {
                Console.WriteLine($"❌ Échec de la synchronisation OSM: {osmResult.ErrorMessage}");
                return new PharmacySyncResult
                {
                    Success = false,
                    ErrorMessage = $"Échec sync OSM: {osmResult.ErrorMessage}",
                    SyncedAt = DateTime.UtcNow,
                    Duration = DateTime.UtcNow - startTime
                };
            }

            Console.WriteLine($"✅ Phase 1 terminée : {osmResult.SyncedCount} pharmacie(s) synchronisée(s)");
            Console.WriteLine();

            // 2️⃣ Scraper pharmacies-de-garde.ci
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Console.WriteLine("📍 PHASE 2/4 : Scraping pharmacies-de-garde.ci");
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            var guardPharmacies = await _scraperService.FetchGuardPharmaciesAsync();
            Console.WriteLine($"✅ Phase 2 terminée : {guardPharmacies.Count} pharmacie(s) de garde scrapée(s)");
            Console.WriteLine();

            // 3️⃣ Fusionner OSM + données de garde
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Console.WriteLine("📍 PHASE 3/4 : Fusion intelligente OSM + Scraping");
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            var osmPharmacies = await _osmSyncService.GetOsmPharmaciesAsync();
            var mergeResult = await _mergerService.MergeGuardDataAsync(osmPharmacies, guardPharmacies);
            Console.WriteLine($"✅ Phase 3 terminée : {mergeResult.Matched} matchés, {mergeResult.Unmatched} non-matchés");
            Console.WriteLine();

            // 4️⃣ Upload le JSON
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Console.WriteLine("📍 PHASE 4/4 : Génération et upload du JSON");
            Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            var publicUrl = await UploadJsonToStorageAsync();
            Console.WriteLine("✅ Phase 4 terminée");
            Console.WriteLine();

            var duration = DateTime.UtcNow - startTime;

            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine($"║  ✅ SYNCHRONISATION COMPLÈTE RÉUSSIE                ║");
            Console.WriteLine($"║  ⏱️  Durée : {duration.TotalSeconds:F1}s                          ║");
            Console.WriteLine($"║  📊 OSM : {osmResult.SyncedCount} pharmacies                        ║");
            Console.WriteLine($"║  🏥 Garde : {guardPharmacies.Count} pharmacies de garde             ║");
            Console.WriteLine($"║  🔗 Matchés : {mergeResult.Matched}                                ║");
            Console.WriteLine($"║  📍 URL : {publicUrl}");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();

            return new PharmacySyncResult
            {
                Success = true,
                PublicUrl = publicUrl,
                SyncedAt = DateTime.UtcNow,
                Duration = duration
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la synchronisation complète: {ex.Message}");
            return new PharmacySyncResult
            {
                Success = false,
                ErrorMessage = ex.Message,
                SyncedAt = DateTime.UtcNow
            };
        }
    }
}

/// <summary>
/// Structure du JSON versionné
/// </summary>
public class PharmacyJsonData
{
    [JsonPropertyName("version")]
    public long Version { get; set; }

    [JsonPropertyName("generated_at")]
    public DateTime GeneratedAt { get; set; }

    [JsonPropertyName("pharmacies")]
    public List<PharmacyJsonDto> Pharmacies { get; set; } = new();
}

/// <summary>
/// DTO pour le JSON des pharmacies
/// </summary>
public class PharmacyJsonDto
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("commune")]
    public string Commune { get; set; } = string.Empty;

    [JsonPropertyName("quartier")]
    public string Quartier { get; set; } = string.Empty;

    [JsonPropertyName("phone")]
    public string Phone { get; set; } = string.Empty;

    [JsonPropertyName("assurances")]
    public string[] Assurances { get; set; } = Array.Empty<string>();

    [JsonPropertyName("open_hours")]
    public OpenHoursDto? OpenHours { get; set; }

    [JsonPropertyName("is_guard")]
    public bool IsGuard { get; set; }

    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// DTO pour les horaires dans le JSON
/// </summary>
public class OpenHoursDto
{
    [JsonPropertyName("open")]
    public string Open { get; set; } = string.Empty;

    [JsonPropertyName("close")]
    public string Close { get; set; } = string.Empty;
}

/// <summary>
/// Résultat de la synchronisation
/// </summary>
public class PharmacySyncResult
{
    public bool Success { get; set; }
    public string? PublicUrl { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime SyncedAt { get; set; }
    public TimeSpan Duration { get; set; }
}
