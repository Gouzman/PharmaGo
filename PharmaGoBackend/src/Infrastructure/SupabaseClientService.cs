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
    private readonly Supabase.Client _client;
    private readonly string _bucketName = "pharmacy_data";
    private readonly string _jsonFileName = "pharmacies.json";

    public SupabaseClientService(string supabaseUrl, string supabaseKey)
    {
        var options = new Supabase.SupabaseOptions
        {
            AutoConnectRealtime = true
        };

        _client = new Supabase.Client(supabaseUrl, supabaseKey, options);
    }

    /// <summary>
    /// Initialise la connexion Supabase
    /// </summary>
    public async Task InitializeAsync()
    {
        await _client.InitializeAsync();
    }

    /// <summary>
    /// Supprime une pharmacie par son ID
    /// </summary>
    public async Task DeletePharmacyAsync(string pharmacyId)
    {
        await _client
            .From<PharmacyDto>()
            .Where(x => x.Id == pharmacyId)
            .Delete();
    }

    /// <summary>
    /// Récupère toutes les pharmacies depuis Supabase
    /// </summary>
    public async Task<List<Pharmacy>> GetPharmaciesAsync()
    {
        try
        {
            var response = await _client
                .From<PharmacyDto>()
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
            var today = DateTime.UtcNow.Date;
            var response = await _client
                .From<GuardScheduleDto>()
                .Where(x => x.GuardDate == today && x.IsActive == true)
                .Get();

            return response.Models.Select(dto => new GuardSchedule
            {
                Id = dto.Id,
                PharmacyId = dto.PharmacyId,
                Start = dto.GuardDate,
                End = dto.GuardDate.AddDays(1),
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
            // 1️⃣ Récupérer toutes les pharmacies actuellement en garde
            var currentGuards = await _client
                .From<PharmacyDto>()
                .Where(x => x.IsGuard == true)
                .Get();

            // 2️⃣ Désactiver toutes les pharmacies actuellement en garde
            foreach (var guard in currentGuards.Models)
            {
                guard.IsGuard = false;
                guard.UpdatedAt = DateTime.UtcNow;
                await _client
                    .From<PharmacyDto>()
                    .Update(guard);
            }

            // 3️⃣ Si aucune pharmacie de garde → STOP
            if (guardPharmacyIds == null || guardPharmacyIds.Count == 0)
            {
                Console.WriteLine("ℹ️ Aucune pharmacie de garde à activer");
                return;
            }

            // 4️⃣ Activer les nouvelles pharmacies de garde
            foreach (var pharmacyId in guardPharmacyIds)
            {
                var pharmacy = await _client
                    .From<PharmacyDto>()
                    .Where(x => x.Id == pharmacyId)
                    .Single();

                if (pharmacy != null)
                {
                    pharmacy.IsGuard = true;
                    pharmacy.UpdatedAt = DateTime.UtcNow;
                    await _client
                        .From<PharmacyDto>()
                        .Update(pharmacy);
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
            if (buckets != null && !buckets.Any(b => b.Name == _bucketName))
            {
                await _client.Storage.CreateBucket(_bucketName, new Supabase.Storage.BucketUpsertOptions
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

    /// <summary>
    /// Insère une nouvelle pharmacie dans Supabase
    /// </summary>
    public async Task InsertPharmacyAsync(Pharmacy pharmacy)
    {
        try
        {
            var dto = new PharmacyDto
            {
                Id = pharmacy.Id,
                Name = pharmacy.Name,
                Lat = pharmacy.Lat,
                Lng = pharmacy.Lng,
                Address = pharmacy.Address,
                Phone = pharmacy.Phone,
                Commune = pharmacy.Commune,
                Quartier = pharmacy.Quartier,
                Assurances = pharmacy.Assurances,
                IsGuard = pharmacy.IsGuard,
                UpdatedAt = pharmacy.UpdatedAt,
                OpenHours = pharmacy.OpenHours != null ? new OpeningHoursDto
                {
                    Open = pharmacy.OpenHours.Open,
                    Close = pharmacy.OpenHours.Close
                } : null
            };

            await _client
                .From<PharmacyDto>()
                .Insert(dto);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de l'insertion de la pharmacie {pharmacy.Id}: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Met à jour une pharmacie existante dans Supabase
    /// </summary>
    public async Task UpdatePharmacyAsync(Pharmacy pharmacy)
    {
        try
        {
            var dto = new PharmacyDto
            {
                Id = pharmacy.Id,
                Name = pharmacy.Name,
                Lat = pharmacy.Lat,
                Lng = pharmacy.Lng,
                Address = pharmacy.Address,
                Phone = pharmacy.Phone,
                Commune = pharmacy.Commune,
                Quartier = pharmacy.Quartier,
                Assurances = pharmacy.Assurances,
                IsGuard = pharmacy.IsGuard,
                UpdatedAt = DateTime.UtcNow,
                OpenHours = pharmacy.OpenHours != null ? new OpeningHoursDto
                {
                    Open = pharmacy.OpenHours.Open,
                    Close = pharmacy.OpenHours.Close
                } : null
            };

            await _client
                .From<PharmacyDto>()
                .Update(dto);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur lors de la mise à jour de la pharmacie {pharmacy.Id}: {ex.Message}");
            throw;
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
/// DTO pour la table guard_schedule dans Supabase
/// </summary>
[Supabase.Postgrest.Attributes.Table("guard_schedule")]
public class GuardScheduleDto : Supabase.Postgrest.Models.BaseModel
{
    [Supabase.Postgrest.Attributes.PrimaryKey("id")]
    public string Id { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("pharmacy_id")]
    public string PharmacyId { get; set; } = string.Empty;

    [Supabase.Postgrest.Attributes.Column("guard_date")]
    public DateTime GuardDate { get; set; }

    [Supabase.Postgrest.Attributes.Column("start_time")]
    public TimeSpan? StartTime { get; set; }

    [Supabase.Postgrest.Attributes.Column("end_time")]
    public TimeSpan? EndTime { get; set; }

    [Supabase.Postgrest.Attributes.Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Supabase.Postgrest.Attributes.Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
