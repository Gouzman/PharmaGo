using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PharmaGo.Application;
using PharmaGo.Cron;
using PharmaGo.Infrastructure;

namespace PharmaGo.API.Controllers;

/// <summary>
/// Contrôleur API pour la gestion des pharmacies
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PharmaciesController : ControllerBase
{
    private readonly ILogger<PharmaciesController> _logger;
    private readonly PharmacyRepository _repository;
    private readonly PharmacySyncService _syncService;
    private readonly PharmacyUpdater _pharmacyUpdater;
    private readonly GuardUpdater _guardUpdater;
    private readonly IConfiguration _configuration;

    public PharmaciesController(
        ILogger<PharmaciesController> logger,
        PharmacyRepository repository,
        PharmacySyncService syncService,
        PharmacyUpdater pharmacyUpdater,
        GuardUpdater guardUpdater,
        IConfiguration configuration)
    {
        _logger = logger;
        _repository = repository;
        _syncService = syncService;
        _pharmacyUpdater = pharmacyUpdater;
        _guardUpdater = guardUpdater;
        _configuration = configuration;
    }

    /// <summary>
    /// Récupère l'URL publique du fichier JSON des pharmacies
    /// </summary>
    /// <returns>URL publique du JSON stocké dans Supabase Storage</returns>
    [HttpGet("latest")]
    [ProducesResponseType(typeof(LatestPharmaciesResponse), 200)]
    public IActionResult GetLatest()
    {
        try
        {
            var supabaseUrl = _configuration["Supabase:Url"];
            var bucketName = "pharmacy_data";
            var fileName = "pharmacies.json";

            var publicUrl = $"{supabaseUrl}/storage/v1/object/public/{bucketName}/{fileName}";

            _logger.LogInformation("📡 URL du JSON des pharmacies demandée: {Url}", publicUrl);

            return Ok(new LatestPharmaciesResponse
            {
                Url = publicUrl,
                CacheMaxAge = 21600 // 6 heures en secondes
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la récupération de l'URL");
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Récupère toutes les pharmacies (endpoint de secours)
    /// </summary>
    [HttpGet]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetAll()
    {
        try
        {
            var pharmacies = await _repository.GetAllAsync();
            _logger.LogInformation("📋 {Count} pharmacie(s) récupérée(s)", pharmacies.Count);
            return Ok(pharmacies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la récupération des pharmacies");
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Récupère une pharmacie par ID
    /// </summary>
    [HttpGet("{id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetById(string id)
    {
        try
        {
            var pharmacy = await _repository.GetByIdAsync(id);
            if (pharmacy == null)
            {
                _logger.LogWarning("⚠️ Pharmacie non trouvée: {Id}", id);
                return NotFound(new { error = "Pharmacie non trouvée" });
            }

            return Ok(pharmacy);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la récupération de la pharmacie {Id}", id);
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Récupère les pharmacies de garde
    /// </summary>
    [HttpGet("guard")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetGuardPharmacies()
    {
        try
        {
            var guardPharmacies = await _repository.GetGuardPharmaciesAsync();
            _logger.LogInformation("🏥 {Count} pharmacie(s) de garde", guardPharmacies.Count);
            return Ok(guardPharmacies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la récupération des pharmacies de garde");
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Récupère les pharmacies par commune
    /// </summary>
    [HttpGet("commune/{commune}")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetByCommune(string commune)
    {
        try
        {
            var pharmacies = await _repository.GetByCommuneAsync(commune);
            _logger.LogInformation("📍 {Count} pharmacie(s) dans {Commune}", pharmacies.Count, commune);
            return Ok(pharmacies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la récupération des pharmacies de {Commune}", commune);
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Récupère les pharmacies à proximité
    /// </summary>
    [HttpGet("nearby")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetNearby([FromQuery] double lat, [FromQuery] double lng, [FromQuery] double radius = 5.0)
    {
        try
        {
            var pharmacies = await _repository.GetNearbyAsync(lat, lng, radius);
            _logger.LogInformation("📍 {Count} pharmacie(s) dans un rayon de {Radius}km", pharmacies.Count, radius);
            return Ok(pharmacies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la recherche de pharmacies à proximité");
            return StatusCode(500, new { error = "Erreur serveur" });
        }
    }

    /// <summary>
    /// Force la synchronisation complète (admin)
    /// </summary>
    [HttpPost("sync")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> ForceSync()
    {
        try
        {
            _logger.LogInformation("⚡ Synchronisation forcée demandée");
            var result = await _syncService.FullSyncAsync();

            if (result.Success)
            {
                return Ok(new
                {
                    success = true,
                    url = result.PublicUrl,
                    syncedAt = result.SyncedAt,
                    duration = result.Duration.TotalSeconds
                });
            }
            else
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = result.ErrorMessage
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la synchronisation forcée");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Force la mise à jour des gardes (admin)
    /// </summary>
    [HttpPost("guard/update")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> ForceGuardUpdate()
    {
        try
        {
            _logger.LogInformation("⚡ Mise à jour des gardes forcée");
            await _guardUpdater.ForceUpdateAsync();
            return Ok(new { success = true, message = "Mise à jour des gardes effectuée" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la mise à jour forcée des gardes");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Vérifie le statut de santé du backend
    /// </summary>
    [HttpGet("health")]
    [ProducesResponseType(200)]
    public IActionResult Health()
    {
        return Ok(new
        {
            status = "healthy",
            timestamp = DateTime.UtcNow,
            version = "1.0.0"
        });
    }
}

/// <summary>
/// Réponse pour l'endpoint /latest
/// </summary>
public class LatestPharmaciesResponse
{
    /// <summary>
    /// URL publique du fichier JSON
    /// </summary>
    public string Url { get; set; } = string.Empty;

    /// <summary>
    /// Durée de cache recommandée en secondes
    /// </summary>
    public int CacheMaxAge { get; set; }
}
