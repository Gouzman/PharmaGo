using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PharmaGo.Application;

namespace PharmaGo.Cron;

/// <summary>
/// Service CRON pour la mise à jour automatique du fichier JSON des pharmacies
/// S'exécute une fois par jour à 3h du matin (heure serveur)
/// </summary>
public class PharmacyUpdater : BackgroundService
{
    private readonly ILogger<PharmacyUpdater> _logger;
    private readonly PharmacySyncService _syncService;
    private readonly TimeSpan _updateInterval = TimeSpan.FromDays(1); // Une fois par jour
    private readonly TimeSpan _targetTime = new TimeSpan(3, 0, 0); // 3h du matin

    public PharmacyUpdater(ILogger<PharmacyUpdater> logger, PharmacySyncService syncService)
    {
        _logger = logger;
        _syncService = syncService;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🕐 PharmacyUpdater démarré - Planifié à {Time} chaque jour", _targetTime);

        // Exécuter immédiatement au démarrage (pour initialiser les données)
        await RunAutoSyncAsync();

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // Calculer le délai jusqu'à la prochaine exécution (3h du matin)
                var now = DateTime.Now;
                var nextRun = now.Date.Add(_targetTime);

                // Si on a dépassé 3h aujourd'hui, planifier pour demain
                if (now > nextRun)
                {
                    nextRun = nextRun.AddDays(1);
                }

                var delay = nextRun - now;

                _logger.LogInformation("⏰ Prochaine synchronisation prévue à : {NextRun} (dans {Hours}h {Minutes}m)", 
                    nextRun.ToString("yyyy-MM-dd HH:mm:ss"), 
                    (int)delay.TotalHours, 
                    delay.Minutes);

                // Attendre jusqu'à la prochaine exécution
                await Task.Delay(delay, stoppingToken);

                // Exécuter la synchronisation
                await RunAutoSyncAsync();
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("⏹️ PharmacyUpdater en cours d'arrêt...");
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Erreur dans PharmacyUpdater");
                // En cas d'erreur, attendre 1 heure avant de réessayer
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            }
        }

        _logger.LogInformation("⏹️ PharmacyUpdater arrêté");
    }

    /// <summary>
    /// Exécute la synchronisation automatique complète
    /// </summary>
    public async Task RunAutoSyncAsync()
    {
        try
        {
            _logger.LogInformation("🚀 Démarrage de la synchronisation automatique...");

            var result = await _syncService.FullSyncAsync();

            if (result.Success)
            {
                _logger.LogInformation(
                    "✅ Synchronisation réussie en {Duration:F2}s - URL: {Url}",
                    result.Duration.TotalSeconds,
                    result.PublicUrl
                );
            }
            else
            {
                _logger.LogError(
                    "❌ Échec de la synchronisation: {Error}",
                    result.ErrorMessage
                );
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la synchronisation automatique");
            throw;
        }
    }

    /// <summary>
    /// Méthode manuelle pour forcer la synchronisation
    /// </summary>
    public async Task ForceSyncAsync()
    {
        _logger.LogInformation("⚡ Synchronisation forcée demandée");
        await RunAutoSyncAsync();
    }
}
