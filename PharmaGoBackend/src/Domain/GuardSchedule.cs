using System;

namespace PharmaGo.Domain;

/// <summary>
/// Représente un planning de garde pour une pharmacie
/// </summary>
public class GuardSchedule
{
    /// <summary>
    /// Identifiant unique du planning
    /// </summary>
    public string Id { get; set; } = Guid.NewGuid().ToString();

    /// <summary>
    /// Identifiant de la pharmacie de garde
    /// </summary>
    public string PharmacyId { get; set; } = string.Empty;

    /// <summary>
    /// Date et heure de début de garde
    /// </summary>
    public DateTime Start { get; set; }

    /// <summary>
    /// Date et heure de fin de garde
    /// </summary>
    public DateTime End { get; set; }

    /// <summary>
    /// Date de création de l'entrée
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Vérifie si la garde est active à la date donnée
    /// </summary>
    public bool IsActiveAt(DateTime dateTime)
    {
        return dateTime >= Start && dateTime <= End;
    }

    /// <summary>
    /// Vérifie si la garde est active actuellement
    /// </summary>
    public bool IsCurrentlyActive()
    {
        return IsActiveAt(DateTime.UtcNow);
    }
}
