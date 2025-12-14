using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PharmaGo.Application;

namespace PharmaGo.Cron;

/// <summary>
/// Service CRON pour la mise à jour quotidienne des pharmacies de garde
/// S'exécute tous les jours à 00:00 UTC
/// </summary>
public class GuardUpdater : BackgroundService
{
    private readonly ILogger<GuardUpdater> _logger;
    private readonly PharmacySyncService _syncService;
    private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(30); // Vérifier toutes les 30 minutes
    private DateTime _lastRunDate = DateTime.MinValue;

    public GuardUpdater(ILogger<GuardUpdater> logger, PharmacySyncService syncService)
    {
        _logger = logger;
        _syncService = syncService;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🕐 GuardUpdater démarré");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var now = DateTime.UtcNow;

                // Vérifier si on doit exécuter (00:00 UTC)
                if (ShouldRunNow(now))
                {
                    _logger.LogInformation("🔄 Démarrage de la mise à jour quotidienne des gardes...");
                    await RunDailyGuardUpdateAsync();
                    _lastRunDate = now.Date;
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Erreur dans GuardUpdater");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }

        _logger.LogInformation("⏹️ GuardUpdater arrêté");
    }

    /// <summary>
    /// Vérifie si la mise à jour doit être exécutée
    /// </summary>
    private bool ShouldRunNow(DateTime now)
    {
        // Exécuter si :
        // 1. On n'a jamais exécuté (première fois)
        // 2. On est sur un nouveau jour ET l'heure est entre 00:00 et 00:30
        if (_lastRunDate == DateTime.MinValue)
            return true;

        if (now.Date > _lastRunDate && now.Hour == 0 && now.Minute < 30)
            return true;

        return false;
    }

    /// <summary>
    /// Exécute la mise à jour quotidienne des pharmacies de garde
    /// </summary>
    public async Task RunDailyGuardUpdateAsync()
    {
        try
        {
            _logger.LogInformation("🏥 Mise à jour des pharmacies de garde...");

            var result = await _syncService.SyncGuardPharmaciesAsync();

            _logger.LogInformation("✅ Mise à jour des gardes terminée avec succès");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erreur lors de la mise à jour des gardes");
            throw;
        }
    }

    /// <summary>
    /// Méthode manuelle pour forcer la mise à jour
    /// </summary>
    public async Task ForceUpdateAsync()
    {
        _logger.LogInformation("⚡ Mise à jour forcée des gardes demandée");
        await RunDailyGuardUpdateAsync();
        _lastRunDate = DateTime.UtcNow.Date;
    }
}
