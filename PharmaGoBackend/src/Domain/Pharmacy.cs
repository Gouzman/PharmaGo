using System;

namespace PharmaGo.Domain;

/// <summary>
/// Représente une pharmacie avec toutes ses informations
/// </summary>
public class Pharmacy
{
    /// <summary>
    /// Identifiant unique de la pharmacie
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// Nom de la pharmacie
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Latitude GPS
    /// </summary>
    public double Lat { get; set; }

    /// <summary>
    /// Longitude GPS
    /// </summary>
    public double Lng { get; set; }

    /// <summary>
    /// Adresse complète
    /// </summary>
    public string Address { get; set; } = string.Empty;

    /// <summary>
    /// Numéro de téléphone
    /// </summary>
    public string Phone { get; set; } = string.Empty;

    /// <summary>
    /// Commune où se trouve la pharmacie
    /// </summary>
    public string Commune { get; set; } = string.Empty;

    /// <summary>
    /// Quartier de la pharmacie
    /// </summary>
    public string Quartier { get; set; } = string.Empty;

    /// <summary>
    /// Liste des assurances acceptées
    /// </summary>
    public string[] Assurances { get; set; } = Array.Empty<string>();

    /// <summary>
    /// Indique si la pharmacie est de garde actuellement
    /// </summary>
    public bool IsGuard { get; set; }

    // ⚠️ DÉSACTIVÉ EN ATTENDANT MIGRATION SQL (voir supabase_migration_v2_history_confidence.sql)
    // /// <summary>
    // /// Score de confiance des données (0-100)
    // /// Basé sur : multiples sources, validation humaine, historique stable
    // /// </summary>
    // public int ConfidenceScore { get; set; } = 60;

    // /// <summary>
    // /// Sources des données (ex: "osm,pharmacies-de-garde.ci")
    // /// </summary>
    // public string DataSources { get; set; } = "osm";

    /// <summary>
    /// Date de dernière mise à jour
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Horaires d'ouverture (optionnel)
    /// </summary>
    public OpeningHours? OpenHours { get; set; }
}

/// <summary>
/// Représente les horaires d'ouverture d'une pharmacie
/// </summary>
public class OpeningHours
{
    /// <summary>
    /// Heure d'ouverture au format HH:mm
    /// </summary>
    public string Open { get; set; } = "08:00";

    /// <summary>
    /// Heure de fermeture au format HH:mm
    /// </summary>
    public string Close { get; set; } = "20:00";
}
