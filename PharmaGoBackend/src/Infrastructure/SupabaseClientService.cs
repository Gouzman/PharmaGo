using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PharmaGo.Domain;
using Supabase;
using Supabase.Storage;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Service de gestion de la connexion et des opérations Supabase
/// </summary>
public class SupabaseClientService
{
    private readonly Client _client;
    private readonly string _bucketName = "pharmacy_data";
    private readonly string _jsonFileName = "pharmacies.json";

    public SupabaseClientService(string supabaseUrl, string supabaseKey)
    {
        var options = new Supabase.SupabaseOptions
        {
            AutoConnectRealtime = true
        };

        _client = new Client(supabaseUrl, supabaseKey, options);
    }

    /// <summary>
    /// Initialise la connexion Supabase
    /// </summary>
    public async Task InitializeAsync()
    {
        await _client.InitializeAsync();
    }

    /// <summary>
    /// Récupère toutes les pharmacies depuis Supabase
    /// </summary>
    public async Task<List<Pharmacy>> GetPharmaciesAsync()
    {
        try
        {
            var response = await _client
                .From<PharmacyDto>("pharmacies")
                .Get();

            return response.Models.Select(dto => new Pharmacy
            {
                Id = dto.Id,
                Name = dto.Name,
                Lat = dto.Lat,
                Lng = dto.Lng,
                Address = dto.Address ?? string.Empty,
                Phone = dto.Phone ?? string.Empty,
                Commune = dto.Commune ?? string.Empty,
                Quartier = dto.Quartier ?? string.Empty,
                Assurances = dto.Assurances ?? Array.Empty<string>(),
                IsGuard = dto.IsGuard,
                UpdatedAt = dto.UpdatedAt,
                OpenHours = dto.OpenHours != null ? new OpeningHours
                {
                    Open = dto.OpenHours.Open,
                    Close = dto.OpenHours.Close
                } : null
            }).ToList();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erreur lors de la récupération des pharmacies: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Récupère les pharmacies de garde actives
    /// </summary>
    public async Task<List<GuardSchedule>> GetActiveGuardSchedulesAsync()
    {
        try
        {
            var now = DateTime.UtcNow;
            var response = await _client
                .From<GuardScheduleDto>("guard_schedules")
                .Where(x => x.Start <= now && x.End >= now)
                .Get();

            return response.Models.Select(dto => new GuardSchedule
            {
                Id = dto.Id,
                PharmacyId = dto.PharmacyId,
                Start = dto.Start,
                End = dto.End,
                CreatedAt = dto.CreatedAt
            }).ToList();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erreur lors de la récupération des gardes: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Met à jour le statut de garde des pharmacies
    /// </summary>
    public async Task UpdateGuardStatusAsync(List<string> guardPharmacyIds)
    {
        try
        {
            // Réinitialiser toutes les pharmacies à non-garde
            await _client
                .From<PharmacyDto>("pharmacies")
                .Set(x => x.IsGuard, false)
                .Update();

            // Marquer les pharmacies de garde
            if (guardPharmacyIds.Any())
            {
                foreach (var pharmacyId in guardPharmacyIds)
                {
                    await _client
                        .From<PharmacyDto>("pharmacies")
                        .Where(x => x.Id == pharmacyId)
                        .Set(x => x.IsGuard, true)
                        .Set(x => x.UpdatedAt, DateTime.UtcNow)
                        .Update();
                }
            }

            Console.WriteLine($"✅ Statut de garde mis à jour pour {guardPharmacyIds.Count} pharmacie(s)");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la mise à jour du statut de garde: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Upload le fichier JSON dans Supabase Storage
    /// </summary>
    public async Task<string> UploadJsonAsync(string jsonContent)
    {
        try
        {
            var bytes = Encoding.UTF8.GetBytes(jsonContent);

            // Upload le fichier (upsert automatique)
            await _client.Storage
                .From(_bucketName)
                .Upload(bytes, _jsonFileName, new Supabase.Storage.FileOptions
                {
                    ContentType = "application/json",
                    Upsert = true
                });

            // Récupérer l'URL publique
            var publicUrl = _client.Storage
                .From(_bucketName)
                .GetPublicUrl(_jsonFileName);

            Console.WriteLine($"✅ JSON uploadé avec succès: {publicUrl}");
            return publicUrl;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de l'upload du JSON: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Vérifie et crée le bucket s'il n'existe pas
    /// </summary>
    public async Task EnsureBucketExistsAsync()
    {
        try
        {
            var buckets = await _client.Storage.ListBuckets();
            if (!buckets.Any(b => b.Name == _bucketName))
            {
                await _client.Storage.CreateBucket(_bucketName, new Supabase.Storage.BucketOptions
                {
                    Public = true
                });
                Console.WriteLine($"✅ Bucket '{_bucketName}' créé avec succès");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"⚠️ Erreur lors de la vérification du bucket: {ex.Message}");
        }
    }
}

/// <summary>
/// DTO pour la table pharmacies dans Supabase
/// </summary>
[Supabase.Postgrest.Attributes.Table("pharmacies")]
public class PharmacyDto : Supabase.Postgrest.Models.BaseModel
{
    [Supabase.Postgrest.Attributes.PrimaryKey("id")]
    public string Id { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("name")]
    public string Name { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("lat")]
    public double Lat { get; set; }

    [Supabase.Postgrest.Attributes.Column("lng")]
    public double Lng { get; set; }

    [Supabase.Postgrest.Attributes.Column("address")]
    public string? Address { get; set; }

    [Supabase.Postgrest.Attributes.Column("phone")]
    public string? Phone { get; set; }

    [Supabase.Postgrest.Attributes.Column("commune")]
    public string? Commune { get; set; }

    [Supabase.Postgrest.Attributes.Column("quartier")]
    public string? Quartier { get; set; }

    [Supabase.Postgrest.Attributes.Column("assurances")]
    public string[]? Assurances { get; set; }

    [Supabase.Postgrest.Attributes.Column("is_guard")]
    public bool IsGuard { get; set; }

    [Supabase.Postgrest.Attributes.Column("updated_at")]
    public DateTime UpdatedAt { get; set; }

    [Supabase.Postgrest.Attributes.Column("open_hours")]
    public OpeningHoursDto? OpenHours { get; set; }
}

/// <summary>
/// DTO pour les horaires d'ouverture
/// </summary>
public class OpeningHoursDto
{
    public string Open { get; set; } = "08:00";
    public string Close { get; set; } = "20:00";
}

/// <summary>
/// DTO pour la table guard_schedules dans Supabase
/// </summary>
[Supabase.Postgrest.Attributes.Table("guard_schedules")]
public class GuardScheduleDto : Supabase.Postgrest.Models.BaseModel
{
    [Supabase.Postgrest.Attributes.PrimaryKey("id")]
    public string Id { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("pharmacy_id")]
    public string PharmacyId { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("start")]
    public DateTime Start { get; set; }

    [Supabase.Postgrest.Attributes.Column("end")]
    public DateTime End { get; set; }

    [Supabase.Postgrest.Attributes.Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
