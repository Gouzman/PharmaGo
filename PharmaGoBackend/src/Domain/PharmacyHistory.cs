using System;

namespace PharmaGo.Domain;

/// <summary>
/// Représente l'historique des modifications d'une pharmacie
/// Permet l'audit, le rollback et la validation de confiance
/// </summary>
public class PharmacyHistory
{
    /// <summary>
    /// Identifiant unique de l'entrée historique
    /// </summary>
    public string Id { get; set; } = Guid.NewGuid().ToString();

    /// <summary>
    /// ID de la pharmacie concernée
    /// </summary>
    public string PharmacyId { get; set; } = string.Empty;

    /// <summary>
    /// Type de modification
    /// </summary>
    public string ChangeType { get; set; } = string.Empty; // "created", "updated", "guard_status_changed", etc.

    /// <summary>
    /// Source de la modification
    /// </summary>
    public string Source { get; set; } = string.Empty; // "osm", "pharmacies-de-garde.ci", "manual", "user_report"

    /// <summary>
    /// Anciennes valeurs (JSON)
    /// </summary>
    public string? OldValues { get; set; }

    /// <summary>
    /// Nouvelles valeurs (JSON)
    /// </summary>
    public string? NewValues { get; set; }

    /// <summary>
    /// Champ modifié
    /// </summary>
    public string? FieldChanged { get; set; }

    /// <summary>
    /// Ancienne valeur du champ
    /// </summary>
    public string? OldValue { get; set; }

    /// <summary>
    /// Nouvelle valeur du champ
    /// </summary>
    public string? NewValue { get; set; }

    /// <summary>
    /// Utilisateur ayant effectué la modification (si applicable)
    /// </summary>
    public string? ModifiedBy { get; set; }

    /// <summary>
    /// Date de la modification
    /// </summary>
    public DateTime ModifiedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Notes ou raison de la modification
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// Indique si cette modification nécessite une révision humaine
    /// </summary>
    public bool NeedsReview { get; set; }

    /// <summary>
    /// Indique si la modification a été validée
    /// </summary>
    public bool IsValidated { get; set; }

    /// <summary>
    /// Date de validation (si applicable)
    /// </summary>
    public DateTime? ValidatedAt { get; set; }

    /// <summary>
    /// Utilisateur ayant validé (si applicable)
    /// </summary>
    public string? ValidatedBy { get; set; }
}

/// <summary>
/// Métadonnées de confiance et qualité des données
/// </summary>
public class PharmacyMetadata
{
    /// <summary>
    /// ID de la pharmacie
    /// </summary>
    public string PharmacyId { get; set; } = string.Empty;

    /// <summary>
    /// Score de confiance (0-100)
    /// Basé sur : sources multiples, validation humaine, cohérence historique
    /// </summary>
    public int ConfidenceScore { get; set; }

    /// <summary>
    /// Nombre de sources confirmant cette pharmacie
    /// </summary>
    public int SourceCount { get; set; }

    /// <summary>
    /// Liste des sources (séparées par virgule)
    /// Ex: "osm,pharmacies-de-garde.ci,manual"
    /// </summary>
    public string Sources { get; set; } = string.Empty;

    /// <summary>
    /// Indique si les données ont été validées par un humain
    /// </summary>
    public bool IsHumanValidated { get; set; }

    /// <summary>
    /// Date de dernière validation humaine
    /// </summary>
    public DateTime? LastHumanValidation { get; set; }

    /// <summary>
    /// Nombre de signalements utilisateurs
    /// </summary>
    public int UserReportCount { get; set; }

    /// <summary>
    /// Indique si cette pharmacie nécessite une révision
    /// </summary>
    public bool NeedsReview { get; set; }

    /// <summary>
    /// Raison de la révision nécessaire
    /// </summary>
    public string? ReviewReason { get; set; }

    /// <summary>
    /// Date de création des métadonnées
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Date de dernière mise à jour
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
