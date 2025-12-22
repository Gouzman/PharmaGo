using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using PharmaGo.Domain;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Repository pour la gestion de l'historique des pharmacies
/// </summary>
public class PharmacyHistoryRepository
{
    private readonly SupabaseClientService _supabaseClient;

    public PharmacyHistoryRepository(SupabaseClientService supabaseClient)
    {
        _supabaseClient = supabaseClient;
    }

    /// <summary>
    /// Enregistre un changement dans l'historique
    /// </summary>
    public async Task RecordChangeAsync(PharmacyHistory history)
    {
        try
        {
            // Utiliser l'API Supabase pour insérer dans la table pharmacy_history
            await _supabaseClient.InsertHistoryAsync(history);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"⚠️ Erreur enregistrement historique: {ex.Message}");
        }
    }

    /// <summary>
    /// Enregistre plusieurs changements en batch
    /// </summary>
    public async Task RecordBatchChangesAsync(List<PharmacyHistory> histories)
    {
        foreach (var history in histories)
        {
            await RecordChangeAsync(history);
        }
    }

    /// <summary>
    /// Récupère l'historique d'une pharmacie
    /// </summary>
    public async Task<List<PharmacyHistory>> GetHistoryAsync(string pharmacyId)
    {
        try
        {
            return await _supabaseClient.GetPharmacyHistoryAsync(pharmacyId);
        }
        catch
        {
            return new List<PharmacyHistory>();
        }
    }

    /// <summary>
    /// Compte le nombre de modifications d'une pharmacie
    /// </summary>
    public async Task<int> GetChangeCountAsync(string pharmacyId)
    {
        try
        {
            var history = await GetHistoryAsync(pharmacyId);
            return history.Count;
        }
        catch
        {
            return 0;
        }
    }

    /// <summary>
    /// Enregistre un conflit de matching (plusieurs pharmacies OSM correspondent)
    /// </summary>
    public async Task CreateConflictAsync(GuardPharmacyInfo guardInfo, List<Pharmacy> candidates)
    {
        var conflictData = new
        {
            guard_pharmacy = guardInfo,
            osm_candidates = candidates.Select(c => new { c.Id, c.Name, c.Commune }).ToList()
        };

        await RecordChangeAsync(new PharmacyHistory
        {
            PharmacyId = "conflict_" + Guid.NewGuid().ToString("N")[..8],
            ChangeType = "matching_conflict",
            Source = "merge_service",
            Notes = $"Conflit de matching pour {guardInfo.Name}",
            OldValues = JsonSerializer.Serialize(conflictData),
            NeedsReview = true
        });
    }

    /// <summary>
    /// Enregistre une pharmacie de garde non matchée
    /// </summary>
    public async Task RecordUnmatchedGuardAsync(GuardPharmacyInfo guardInfo)
    {
        await RecordChangeAsync(new PharmacyHistory
        {
            PharmacyId = "unmatched_" + Guid.NewGuid().ToString("N")[..8],
            ChangeType = "unmatched_guard",
            Source = "pharmacies-de-garde.ci",
            Notes = $"Pharmacie de garde non trouvée dans OSM: {guardInfo.Name}",
            NewValues = JsonSerializer.Serialize(guardInfo),
            NeedsReview = true
        });
    }

    /// <summary>
    /// Récupère toutes les entrées nécessitant une révision
    /// </summary>
    public async Task<List<PharmacyHistory>> GetEntriesNeedingReviewAsync()
    {
        try
        {
            return await _supabaseClient.GetHistoryNeedingReviewAsync();
        }
        catch
        {
            return new List<PharmacyHistory>();
        }
    }

    /// <summary>
    /// Marque une entrée comme validée
    /// </summary>
    public async Task ValidateEntryAsync(string historyId, string validatedBy)
    {
        try
        {
            await _supabaseClient.ValidateHistoryEntryAsync(historyId, validatedBy);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"⚠️ Erreur validation: {ex.Message}");
        }
    }
}
