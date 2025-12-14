using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PharmaGo.Application;

namespace PharmaGo.Cron;

/// <summary>
/// Service CRON pour la mise à jour automatique du fichier JSON des pharmacies
/// S'exécute toutes les 6 heures
/// </summary>
public class PharmacyUpdater : BackgroundService
{
    private readonly ILogger<PharmacyUpdater> _logger;
    private readonly PharmacySyncService _syncService;
    private readonly TimeSpan _updateInterval = TimeSpan.FromHours(6); // Toutes les 6 heures

    public PharmacyUpdater(ILogger<PharmacyUpdater> logger, PharmacySyncService syncService)
    {
        _logger = logger;
        _syncService = syncService;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🕐 PharmacyUpdater démarré - Intervalle: {Interval} heures", _updateInterval.TotalHours);

        // Exécuter immédiatement au démarrage
        await RunAutoSyncAsync();

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // Attendre l'intervalle configuré
                await Task.Delay(_updateInterval, stoppingToken);

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
                // En cas d'erreur, attendre 30 minutes avant de réessayer
                await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
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
