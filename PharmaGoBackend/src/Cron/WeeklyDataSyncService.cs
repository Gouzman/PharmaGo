using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PharmaGo.Infrastructure;

namespace PharmaGo.Cron;

/// <summary>
/// Service CRON hebdomadaire pour la synchronisation complète
/// Exécute : OSM + Scraping pharmacies-de-garde.ci + Fusion + Génération JSON
/// ⏰ Planifié : 1 fois / semaine (Dimanche 22h00 UTC)
/// </summary>
public class WeeklyDataSyncService : BackgroundService
{
    private readonly ILogger<WeeklyDataSyncService> _logger;
    private readonly OsmSyncService _osmSyncService;
    private readonly PharmaciesDeGardeScraperService _guardScraperService;
    private readonly PharmacyDataMergerService _mergerService;
    private readonly Application.PharmacySyncService _pharmacySyncService;

    private readonly TimeSpan _checkInterval = TimeSpan.FromHours(1); // Vérifier toutes les heures
    private DateTime _lastRunDate = DateTime.MinValue;

    public WeeklyDataSyncService(
        ILogger<WeeklyDataSyncService> logger,
        OsmSyncService osmSyncService,
        PharmaciesDeGardeScraperService guardScraperService,
        PharmacyDataMergerService mergerService,
        Application.PharmacySyncService pharmacySyncService)
    {
        _logger = logger;
        _osmSyncService = osmSyncService;
        _guardScraperService = guardScraperService;
        _mergerService = mergerService;
        _pharmacySyncService = pharmacySyncService;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("╔═══════════════════════════════════════════════════════╗");
        _logger.LogInformation("║   🕐 WEEKLY DATA SYNC SERVICE - DÉMARRÉ              ║");
        _logger.LogInformation("║   📅 Planification : Dimanche 22h00 UTC              ║");
        _logger.LogInformation("╚═══════════════════════════════════════════════════════╝");

        // Exécution immédiate au démarrage (1 seule fois)
        _logger.LogInformation("🚀 Exécution initiale au démarrage...");
        await RunWeeklySyncAsync();
        _lastRunDate = DateTime.UtcNow.Date;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var now = DateTime.UtcNow;

                // Vérifier si on doit exécuter (Dimanche 22h00 UTC)
                if (ShouldRunNow(now))
                {
                    _logger.LogInformation("⏰ Démarrage de la synchronisation hebdomadaire planifiée...");
                    await RunWeeklySyncAsync();
                    _lastRunDate = now.Date;
                }

                // Afficher la prochaine exécution planifiée
                var nextRun = CalculateNextRun(now);
                _logger.LogInformation($"⏰ Prochaine sync : {nextRun:yyyy-MM-dd HH:mm} UTC (dans {(nextRun - now).TotalHours:F1}h)");

                await Task.Delay(_checkInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("⏹️ WeeklyDataSyncService en cours d'arrêt...");
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Erreur dans WeeklyDataSyncService");
                await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
            }
        }

        _logger.LogInformation("⏹️ WeeklyDataSyncService arrêté");
    }

    /// <summary>
    /// Vérifie si la synchronisation doit s'exécuter maintenant
    /// Critère : Dimanche entre 22h00 et 23h00 UTC ET pas déjà exécuté aujourd'hui
    /// </summary>
    private bool ShouldRunNow(DateTime now)
    {
        // Éviter de ré-exécuter si déjà fait aujourd'hui
        if (_lastRunDate == now.Date)
            return false;

        // Exécuter si :
        // - C'est dimanche (DayOfWeek.Sunday = 0)
        // - Entre 22h00 et 23h00 UTC
        return now.DayOfWeek == DayOfWeek.Sunday
            && now.Hour == 22;
    }

    /// <summary>
    /// Calcule la date de la prochaine exécution
    /// </summary>
    private DateTime CalculateNextRun(DateTime now)
    {
        var nextSunday = now.Date;
        
        // Trouver le prochain dimanche
        while (nextSunday.DayOfWeek != DayOfWeek.Sunday || nextSunday <= now.Date)
        {
            nextSunday = nextSunday.AddDays(1);
        }

        // Ajouter 22h00
        return nextSunday.AddHours(22);
    }

    /// <summary>
    /// Exécute la synchronisation hebdomadaire complète
    /// Pipeline : OSM → Scraping Garde → Fusion → JSON → Upload
    /// </summary>
    public async Task RunWeeklySyncAsync()
    {
        var startTime = DateTime.UtcNow;

        try
        {
            _logger.LogInformation("");
            _logger.LogInformation("╔═══════════════════════════════════════════════════════╗");
            _logger.LogInformation("║                                                       ║");
            _logger.LogInformation("║       🌍 SYNCHRONISATION HEBDOMADAIRE COMPLÈTE       ║");
            _logger.LogInformation("║                                                       ║");
            _logger.LogInformation("╚═══════════════════════════════════════════════════════╝");
            _logger.LogInformation("");

            // 🗺️ ÉTAPE 1 : Synchronisation OSM → Supabase
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            _logger.LogInformation("📍 ÉTAPE 1/4 : Synchronisation OpenStreetMap");
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            var osmResult = await _osmSyncService.SyncPharmaciesFromOsmAsync();
            
            if (!osmResult.Success)
            {
                _logger.LogError($"❌ Échec OSM : {osmResult.ErrorMessage}");
                return;
            }

            _logger.LogInformation($"✅ OSM Sync : {osmResult.SyncedCount} pharmacie(s)");
            _logger.LogInformation("");

            // 🏥 ÉTAPE 2 : Scraping pharmacies-de-garde.ci
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            _logger.LogInformation("📍 ÉTAPE 2/4 : Scraping pharmacies-de-garde.ci");
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            var guardPharmacies = await _guardScraperService.FetchGuardPharmaciesAsync();
            
            _logger.LogInformation($"✅ Garde Scraping : {guardPharmacies.Count} pharmacie(s) de garde");
            _logger.LogInformation("");

            // 🔀 ÉTAPE 3 : Fusion intelligente des données
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            _logger.LogInformation("📍 ÉTAPE 3/4 : Fusion OSM + Garde");
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            var osmPharmacies = await _osmSyncService.GetOsmPharmaciesAsync();
            var mergeResult = await _mergerService.MergeGuardDataAsync(osmPharmacies, guardPharmacies);
            
            _logger.LogInformation($"✅ Fusion : {mergeResult.Matched} matchés, {mergeResult.Unmatched} non-matchés");
            _logger.LogInformation("");

            // 📦 ÉTAPE 4 : Génération JSON versionné
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            _logger.LogInformation("📍 ÉTAPE 4/4 : Génération JSON + Upload Supabase");
            _logger.LogInformation("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            var syncResult = await _pharmacySyncService.FullSyncAsync();
            
            if (!syncResult.Success)
            {
                _logger.LogError($"❌ Échec génération JSON : {syncResult.ErrorMessage}");
                return;
            }

            _logger.LogInformation($"✅ JSON généré : {syncResult.PublicUrl}");
            _logger.LogInformation("");

            // 🎉 RÉSUMÉ FINAL
            var duration = DateTime.UtcNow - startTime;
            
            _logger.LogInformation("╔═══════════════════════════════════════════════════════╗");
            _logger.LogInformation("║                                                       ║");
            _logger.LogInformation("║           ✅ SYNCHRONISATION TERMINÉE !              ║");
            _logger.LogInformation("║                                                       ║");
            _logger.LogInformation($"║   ⏱️  Durée : {duration.TotalMinutes:F1} minutes                     ║");
            _logger.LogInformation($"║   📊 OSM : {osmResult.SyncedCount} pharmacies                       ║");
            _logger.LogInformation($"║   🏥 Garde : {guardPharmacies.Count} pharmacies                     ║");
            _logger.LogInformation($"║   🔀 Fusion : {mergeResult.Matched} matchés                       ║");
            _logger.LogInformation($"║   ⚠️  À réviser : {mergeResult.NeedsReview} conflits                   ║");
            _logger.LogInformation("║                                                       ║");
            _logger.LogInformation("╚═══════════════════════════════════════════════════════╝");
            _logger.LogInformation("");

            // ⚠️ ALERTES si nécessaire
            if (mergeResult.NeedsReview > 0)
            {
                _logger.LogWarning($"⚠️ {mergeResult.NeedsReview} pharmacie(s) nécessitent une révision humaine");
                _logger.LogWarning("   → Consultez la table 'pharmacy_history' avec needs_review=true");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ ERREUR CRITIQUE lors de la synchronisation hebdomadaire");
            throw;
        }
    }

    /// <summary>
    /// Force l'exécution immédiate (pour tests ou déclenchement manuel)
    /// </summary>
    public async Task ForceRunAsync()
    {
        _logger.LogInformation("⚡ Synchronisation forcée déclenchée manuellement");
        await RunWeeklySyncAsync();
    }
}
