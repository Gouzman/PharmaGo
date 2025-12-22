using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using PharmaGo.Domain;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Service de fusion intelligente des données provenant de plusieurs sources
/// OSM (position GPS) + pharmacies-de-garde.ci (statut garde) + historique
/// </summary>
public class PharmacyDataMergerService
{
    private readonly SupabaseClientService _supabaseClient;
    private readonly PharmacyHistoryRepository _historyRepo;

    public PharmacyDataMergerService(
        SupabaseClientService supabaseClient,
        PharmacyHistoryRepository historyRepo)
    {
        _supabaseClient = supabaseClient;
        _historyRepo = historyRepo;
    }

    /// <summary>
    /// Fusionne les données OSM avec les données de garde officielles
    /// </summary>
    public async Task<MergeResult> MergeGuardDataAsync(
        List<Pharmacy> osmPharmacies, 
        List<GuardPharmacyInfo> guardPharmacies)
    {
        try
        {
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine("║        🔀 FUSION INTELLIGENTE DES DONNÉES            ║");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();

            var result = new MergeResult();
            var existingPharmacies = await _supabaseClient.GetPharmaciesAsync();

            // 1️⃣ Marquer toutes les pharmacies comme NON de garde par défaut
            Console.WriteLine("📍 Étape 1/4 : Réinitialisation du statut de garde...");
            foreach (var pharmacy in existingPharmacies)
            {
                if (pharmacy.IsGuard)
                {
                    await UpdateGuardStatus(pharmacy, false, "Rotation hebdomadaire");
                    result.GuardStatusRemoved++;
                }
            }
            Console.WriteLine($"   ✅ {result.GuardStatusRemoved} pharmacie(s) retirée(s) de la garde");

            // 2️⃣ Matcher les pharmacies de garde avec la base OSM
            Console.WriteLine("📍 Étape 2/4 : Matching des pharmacies de garde...");
            foreach (var guardInfo in guardPharmacies)
            {
                var matchedPharmacy = await FindMatchingPharmacy(guardInfo, osmPharmacies);

                if (matchedPharmacy != null)
                {
                    // ✅ Match trouvé : mettre à jour
                    await UpdateGuardStatus(matchedPharmacy, true, "pharmacies-de-garde.ci", guardInfo);
                    result.Matched++;
                    Console.WriteLine($"   ✅ Match: {guardInfo.Name} → {matchedPharmacy.Name}");
                }
                else
                {
                    // ⚠️ Pas de match : créer une nouvelle pharmacie OU marquer pour révision
                    await HandleUnmatchedGuardPharmacy(guardInfo);
                    result.Unmatched++;
                    Console.WriteLine($"   ⚠️ Non matché: {guardInfo.Name} ({guardInfo.City})");
                }
            }

            // 3️⃣ Mettre à jour les scores de confiance
            Console.WriteLine("📍 Étape 3/4 : Calcul des scores de confiance...");
            await UpdateConfidenceScoresAsync();
            Console.WriteLine($"   ✅ Scores mis à jour");

            // 4️⃣ Identifier les conflits nécessitant révision
            Console.WriteLine("📍 Étape 4/4 : Détection des conflits...");
            result.NeedsReview = await DetectConflictsAsync();
            Console.WriteLine($"   ⚠️ {result.NeedsReview} pharmacie(s) à réviser");

            Console.WriteLine();
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine($"║  ✅ FUSION TERMINÉE");
            Console.WriteLine($"║  ✔️ Matchés: {result.Matched}");
            Console.WriteLine($"║  ⚠️ Non matchés: {result.Unmatched}");
            Console.WriteLine($"║  🔍 À réviser: {result.NeedsReview}");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();

            return result;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur fusion: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Trouve une pharmacie OSM correspondante à une pharmacie de garde
    /// </summary>
    private async Task<Pharmacy?> FindMatchingPharmacy(
        GuardPharmacyInfo guardInfo, 
        List<Pharmacy> osmPharmacies)
    {
        // Stratégie de matching multi-critères
        
        // 1️⃣ Normaliser le nom de la pharmacie de garde
        var normalizedGuardName = NormalizeName(guardInfo.Name);

        // 2️⃣ Chercher par nom exact (normalisé)
        var exactMatch = osmPharmacies.FirstOrDefault(p => 
            NormalizeName(p.Name).Equals(normalizedGuardName, StringComparison.OrdinalIgnoreCase));
        
        if (exactMatch != null)
            return exactMatch;

        // 3️⃣ Chercher par similarité de nom + même ville/quartier
        var similarMatches = osmPharmacies.Where(p =>
        {
            var nameSimilarity = CalculateNameSimilarity(p.Name, guardInfo.Name);
            var sameCity = p.Commune.Equals(guardInfo.City, StringComparison.OrdinalIgnoreCase);
            var sameQuartier = !string.IsNullOrEmpty(guardInfo.Quartier) &&
                p.Quartier.Contains(guardInfo.Quartier, StringComparison.OrdinalIgnoreCase);

            return nameSimilarity > 0.7 && (sameCity || sameQuartier);
        }).ToList();

        if (similarMatches.Count == 1)
            return similarMatches[0];

        // 4️⃣ Si plusieurs matches similaires → marquer pour révision humaine
        if (similarMatches.Count > 1)
        {
            await _historyRepo.CreateConflictAsync(guardInfo, similarMatches);
            return null;
        }

        // 5️⃣ Aucun match trouvé
        return null;
    }

    /// <summary>
    /// Met à jour le statut de garde d'une pharmacie
    /// </summary>
    private async Task UpdateGuardStatus(
        Pharmacy pharmacy, 
        bool isGuard, 
        string source,
        GuardPharmacyInfo? guardInfo = null)
    {
        var oldStatus = pharmacy.IsGuard;
        pharmacy.IsGuard = isGuard;
        pharmacy.UpdatedAt = DateTime.UtcNow;

        // Mettre à jour le téléphone si disponible
        if (guardInfo != null && !string.IsNullOrEmpty(guardInfo.Phone))
        {
            pharmacy.Phone = guardInfo.Phone;
        }

        // Sauvegarder dans Supabase
        await _supabaseClient.UpdatePharmacyAsync(pharmacy);

        // Historiser le changement
        if (oldStatus != isGuard)
        {
            await _historyRepo.RecordChangeAsync(new PharmacyHistory
            {
                PharmacyId = pharmacy.Id,
                ChangeType = "guard_status_changed",
                Source = source,
                FieldChanged = "is_guard",
                OldValue = oldStatus.ToString(),
                NewValue = isGuard.ToString(),
                Notes = guardInfo != null 
                    ? $"Garde du {guardInfo.GuardStart:dd/MM} au {guardInfo.GuardEnd:dd/MM}"
                    : "Fin de période de garde"
            });
        }
    }

    /// <summary>
    /// Gère une pharmacie de garde non matchée dans OSM
    /// </summary>
    private async Task HandleUnmatchedGuardPharmacy(GuardPharmacyInfo guardInfo)
    {
        // Option 1 : Créer une nouvelle pharmacie (si on a assez d'infos)
        // Option 2 : Marquer pour révision humaine (recommandé)
        
        await _historyRepo.RecordUnmatchedGuardAsync(guardInfo);
        
        // Pour l'instant, on NE CRÉE PAS automatiquement
        // Car on n'a pas de coordonnées GPS fiables
        // → Nécessite validation humaine + géocodage
    }

    /// <summary>
    /// Normalise un nom de pharmacie pour le matching
    /// </summary>
    private string NormalizeName(string name)
    {
        if (string.IsNullOrEmpty(name))
            return "";

        // Supprimer les accents, mettre en minuscules, supprimer "pharmacie"
        name = name.ToLowerInvariant()
            .Replace("pharmacie", "")
            .Replace("pharmacy", "")
            .Trim();

        // Supprimer caractères spéciaux
        name = new string(name.Where(c => char.IsLetterOrDigit(c) || char.IsWhiteSpace(c)).ToArray());
        
        // Supprimer espaces multiples
        return System.Text.RegularExpressions.Regex.Replace(name, @"\s+", " ").Trim();
    }

    /// <summary>
    /// Calcule la similarité entre deux noms (0.0 à 1.0)
    /// Utilise l'algorithme de Levenshtein simplifié
    /// </summary>
    private double CalculateNameSimilarity(string name1, string name2)
    {
        var normalized1 = NormalizeName(name1);
        var normalized2 = NormalizeName(name2);

        if (normalized1 == normalized2)
            return 1.0;

        // Similarité basique par contenu
        var words1 = normalized1.Split(' ');
        var words2 = normalized2.Split(' ');

        var commonWords = words1.Intersect(words2).Count();
        var totalWords = Math.Max(words1.Length, words2.Length);

        return totalWords > 0 ? (double)commonWords / totalWords : 0.0;
    }

    /// <summary>
    /// Met à jour les scores de confiance pour toutes les pharmacies
    /// </summary>
    private async Task UpdateConfidenceScoresAsync()
    {
        var pharmacies = await _supabaseClient.GetPharmaciesAsync();

        foreach (var pharmacy in pharmacies)
        {
            var score = await CalculateConfidenceScore(pharmacy);
            await _supabaseClient.UpdateConfidenceScoreAsync(pharmacy.Id, score);
        }
    }

    /// <summary>
    /// Calcule le score de confiance d'une pharmacie (0-100)
    /// </summary>
    private async Task<int> CalculateConfidenceScore(Pharmacy pharmacy)
    {
        int score = 0;

        // Base OSM : +60 points (données GPS fiables)
        if (pharmacy.Id.StartsWith("osm_"))
            score += 60;

        // Statut de garde vérifié : +20 points
        if (pharmacy.IsGuard)
            score += 20;

        // Téléphone renseigné : +10 points
        if (!string.IsNullOrEmpty(pharmacy.Phone))
            score += 10;

        // Historique de changements : +10 points (stabilité)
        var historyCount = await _historyRepo.GetChangeCountAsync(pharmacy.Id);
        if (historyCount > 3)
            score += 10;

        return Math.Min(score, 100);
    }

    /// <summary>
    /// Détecte les pharmacies nécessitant une révision humaine
    /// </summary>
    private async Task<int> DetectConflictsAsync()
    {
        // TODO : Implémenter la logique de détection de conflits
        // - Pharmacies avec noms similaires
        // - Pharmacies trop proches géographiquement (< 50m)
        // - Changements fréquents de statut
        return 0;
    }
}

/// <summary>
/// Résultat d'une fusion de données
/// </summary>
public class MergeResult
{
    public int Matched { get; set; }
    public int Unmatched { get; set; }
    public int NeedsReview { get; set; }
    public int GuardStatusRemoved { get; set; }
}
