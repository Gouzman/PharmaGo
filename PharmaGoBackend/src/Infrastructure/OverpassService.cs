using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using PharmaGo.Domain;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Service pour récupérer les pharmacies depuis OpenStreetMap via Overpass API
/// </summary>
public class OverpassService
{
    private readonly HttpClient _httpClient;
    private static readonly string[] OverpassServers = new[]
    {
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
        "https://overpass.openstreetmap.ru/api/interpreter"
    };

    // Bounding box pour Abidjan, Côte d'Ivoire
    // Format : [minLat, minLon, maxLat, maxLon]
    private const double MinLat = 5.20;
    private const double MinLon = -4.20;
    private const double MaxLat = 5.45;
    private const double MaxLon = -3.90;

    public OverpassService(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.Timeout = TimeSpan.FromMinutes(2); // Timeout de 2 minutes
    }

    /// <summary>
    /// Récupère toutes les pharmacies d'Abidjan depuis OpenStreetMap
    /// </summary>
    public async Task<List<Pharmacy>> FetchPharmaciesAsync()
    {
        Exception? lastException = null;

        // Essayer plusieurs serveurs Overpass en cas d'échec
        foreach (var serverUrl in OverpassServers)
        {
            try
            {
                Console.WriteLine($"🔄 Récupération depuis {serverUrl}...");

                // Construire la requête Overpass
                var query = BuildOverpassQuery();
                
                Console.WriteLine($"📝 Requête: {query}");

                // Utiliser GET car c'est plus fiable avec Overpass
                var requestUrl = $"{serverUrl}?data={Uri.EscapeDataString(query)}";

                // Envoyer la requête GET
                var response = await _httpClient.GetAsync(requestUrl);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"⚠️ Serveur {serverUrl} a échoué ({response.StatusCode})");
                    lastException = new HttpRequestException($"Server {serverUrl}: {response.StatusCode}");
                    continue; // Essayer le serveur suivant
                }

                var jsonResponse = await response.Content.ReadAsStringAsync();

            // Parser la réponse
            var overpassResponse = JsonSerializer.Deserialize<OverpassResponse>(jsonResponse);

            if (overpassResponse?.Elements == null || overpassResponse.Elements.Count == 0)
            {
                Console.WriteLine("⚠️ Aucune pharmacie trouvée sur OSM");
                return new List<Pharmacy>();
            }

            // Convertir les éléments OSM en pharmacies
            var pharmaciesRaw = overpassResponse.Elements
                .Select(MapToPharmacy)
                .Where(p => p != null)
                .Cast<Pharmacy>()
                .ToList();

            Console.WriteLine($"📊 {pharmaciesRaw.Count} entrée(s) OSM récupérée(s)");

            // ✅ DÉDUPLICATION par clé unique (nom + coordonnées arrondies)
            var pharmacies = DeduplicatePharmacies(pharmaciesRaw);

            Console.WriteLine($"✅ {pharmacies.Count} pharmacie(s) uniques après déduplication");

            return pharmacies;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Erreur avec le serveur {serverUrl}: {ex.Message}");
                lastException = ex;
                continue; // Essayer le serveur suivant
            }
        }

        // Si tous les serveurs ont échoué
        Console.WriteLine("❌ Tous les serveurs Overpass ont échoué");
        throw lastException ?? new Exception("Impossible de contacter l'API Overpass");
    }    /// <summary>
    /// Construit la requête Overpass pour récupérer les pharmacies
    /// </summary>
    private static string BuildOverpassQuery()
    {
        // Utiliser InvariantCulture pour forcer le point comme séparateur décimal
        var minLat = MinLat.ToString(System.Globalization.CultureInfo.InvariantCulture);
        var minLon = MinLon.ToString(System.Globalization.CultureInfo.InvariantCulture);
        var maxLat = MaxLat.ToString(System.Globalization.CultureInfo.InvariantCulture);
        var maxLon = MaxLon.ToString(System.Globalization.CultureInfo.InvariantCulture);

        // Requête OverpassQL ultra-simplifiée
        // Format bbox: (sud,ouest,nord,est)
        return $"[out:json][timeout:60];(node[amenity=pharmacy]({minLat},{minLon},{maxLat},{maxLon});way[amenity=pharmacy]({minLat},{minLon},{maxLat},{maxLon}););out center;";
    }

    /// <summary>
    /// Convertit un élément OSM en objet Pharmacy
    /// </summary>
    private Pharmacy? MapToPharmacy(OverpassElement element)
    {
        try
        {
            // Déterminer les coordonnées (node direct ou centre d'un way)
            double? lat = element.Lat;
            double? lon = element.Lon;

            // Si c'est un way (bâtiment), utiliser le centre
            if ((!lat.HasValue || !lon.HasValue) && element.Center != null)
            {
                lat = element.Center.Lat;
                lon = element.Center.Lon;
            }

            // Vérifier que nous avons les coordonnées
            if (!lat.HasValue || !lon.HasValue)
            {
                Console.WriteLine($"  ⚠️ Élément {element.Type} {element.Id} sans coordonnées");
                return null;
            }

            // Extraire le nom (obligatoire)
            var name = element.Tags?.GetValueOrDefault("name") 
                ?? element.Tags?.GetValueOrDefault("name:fr")
                ?? $"Pharmacie OSM #{element.Id}";

            // ✅ Filtre qualité : ignorer les noms trop courts ou génériques
            if (!IsValidPharmacyName(name))
            {
                Console.WriteLine($"  ⚠️ Nom invalide ignoré: {name}");
                return null;
            }

            // Extraire l'adresse
            var address = BuildAddress(element.Tags);

            // Extraire la commune
            var commune = element.Tags?.GetValueOrDefault("addr:city")
                ?? element.Tags?.GetValueOrDefault("addr:district")
                ?? DetermineCommune(lat.Value, lon.Value);

            // Extraire le quartier
            var quartier = element.Tags?.GetValueOrDefault("addr:suburb")
                ?? element.Tags?.GetValueOrDefault("addr:neighbourhood")
                ?? element.Tags?.GetValueOrDefault("addr:quarter")
                ?? string.Empty;

            // Extraire le téléphone
            var phone = element.Tags?.GetValueOrDefault("phone")
                ?? element.Tags?.GetValueOrDefault("contact:phone")
                ?? string.Empty;

            // Nettoyer le téléphone (enlever les espaces, +, etc.)
            phone = CleanPhoneNumber(phone);

            // Extraire les horaires d'ouverture
            var openingHours = ParseOpeningHours(element.Tags?.GetValueOrDefault("opening_hours"));

            // Créer la pharmacie
            return new Pharmacy
            {
                Id = $"osm_{element.Type}_{element.Id}",
                Name = name,
                Lat = lat.Value,
                Lng = lon.Value,
                Address = address,
                Commune = commune,
                Quartier = quartier,
                Phone = phone,
                Assurances = Array.Empty<string>(), // Pas d'info sur les assurances dans OSM
                IsGuard = false, // Par défaut, pas de garde
                UpdatedAt = DateTime.UtcNow,
                OpenHours = openingHours
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"⚠️ Erreur lors de la conversion de l'élément OSM {element.Id}: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Construit une adresse à partir des tags OSM
    /// </summary>
    private static string BuildAddress(Dictionary<string, string>? tags)
    {
        if (tags == null) return string.Empty;

        var parts = new List<string>();

        // Numéro de rue
        if (tags.TryGetValue("addr:housenumber", out var houseNumber) && !string.IsNullOrWhiteSpace(houseNumber))
        {
            parts.Add(houseNumber);
        }

        // Nom de la rue
        if (tags.TryGetValue("addr:street", out var street) && !string.IsNullOrWhiteSpace(street))
        {
            parts.Add(street);
        }

        // Si pas d'adresse structurée, chercher addr:full
        if (parts.Count == 0 && tags.TryGetValue("addr:full", out var fullAddress))
        {
            return fullAddress;
        }

        return string.Join(" ", parts);
    }

    /// <summary>
    /// Nettoie un numéro de téléphone
    /// </summary>
    private static string CleanPhoneNumber(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return string.Empty;

        // Garder uniquement les chiffres et le +
        return new string(phone.Where(c => char.IsDigit(c) || c == '+').ToArray());
    }

    /// <summary>
    /// Parse les horaires d'ouverture OSM (format simplifié)
    /// </summary>
    private OpeningHours? ParseOpeningHours(string? openingHoursStr)
    {
        if (string.IsNullOrWhiteSpace(openingHoursStr))
        {
            return null;
        }

        // Format OSM : "Mo-Fr 08:00-20:00; Sa 08:00-18:00"
        // On prend une simplification : premier créneau trouvé
        try
        {
            // Chercher un pattern HH:MM-HH:MM
            var timePattern = System.Text.RegularExpressions.Regex.Match(
                openingHoursStr,
                @"(\d{2}:\d{2})-(\d{2}:\d{2})"
            );

            if (timePattern.Success)
            {
                return new OpeningHours
                {
                    Open = timePattern.Groups[1].Value,
                    Close = timePattern.Groups[2].Value
                };
            }
        }
        catch
        {
            // Ignorer les erreurs de parsing
        }

        return null;
    }

    /// <summary>
    /// Valide le nom d'une pharmacie (qualité minimale)
    /// </summary>
    private static bool IsValidPharmacyName(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            return false;

        // Nom trop court (moins de 3 caractères)
        if (name.Length < 3)
            return false;

        // Noms génériques à exclure
        var genericNames = new[] { "Pharmacie", "Pharmacy", "Aho", "PDZ", "TRV" };
        if (genericNames.Contains(name, StringComparer.OrdinalIgnoreCase))
            return false;

        return true;
    }

    /// <summary>
    /// Déduplique les pharmacies par clé unique (nom normalisé + coordonnées arrondies)
    /// </summary>
    private static List<Pharmacy> DeduplicatePharmacies(List<Pharmacy> pharmacies)
    {
        var seen = new Dictionary<string, Pharmacy>();
        var duplicates = 0;

        foreach (var pharmacy in pharmacies)
        {
            // Créer une clé unique basée sur nom normalisé + coordonnées (5 décimales)
            var normalizedName = NormalizeName(pharmacy.Name);
            var key = $"{normalizedName}_{pharmacy.Lat:F5}_{pharmacy.Lng:F5}";

            if (!seen.ContainsKey(key))
            {
                seen[key] = pharmacy;
            }
            else
            {
                // Doublon détecté : garder celui avec le plus d'infos
                var existing = seen[key];
                if (HasMoreInfo(pharmacy, existing))
                {
                    seen[key] = pharmacy;
                }
                duplicates++;
            }
        }

        if (duplicates > 0)
        {
            Console.WriteLine($"🔄 {duplicates} doublon(s) éliminé(s)");
        }

        return seen.Values.ToList();
    }

    /// <summary>
    /// Normalise un nom pour la déduplication
    /// </summary>
    private static string NormalizeName(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            return string.Empty;

        // Convertir en minuscules, supprimer accents, espaces multiples
        return name.ToLowerInvariant()
            .Replace("pharmacie", "")
            .Replace("pharmacy", "")
            .Trim()
            .Replace("  ", " ");
    }

    /// <summary>
    /// Détermine si une pharmacie a plus d'informations qu'une autre
    /// </summary>
    private static bool HasMoreInfo(Pharmacy a, Pharmacy b)
    {
        var scoreA = 0;
        var scoreB = 0;

        if (!string.IsNullOrWhiteSpace(a.Address)) scoreA++;
        if (!string.IsNullOrWhiteSpace(a.Phone)) scoreA++;
        if (!string.IsNullOrWhiteSpace(a.Quartier)) scoreA++;
        if (a.OpenHours != null) scoreA++;

        if (!string.IsNullOrWhiteSpace(b.Address)) scoreB++;
        if (!string.IsNullOrWhiteSpace(b.Phone)) scoreB++;
        if (!string.IsNullOrWhiteSpace(b.Quartier)) scoreB++;
        if (b.OpenHours != null) scoreB++;

        return scoreA > scoreB;
    }

    /// <summary>
    /// Détermine la commune en fonction des coordonnées GPS
    /// (Approximation basée sur les zones géographiques d'Abidjan)
    /// </summary>
    private static string DetermineCommune(double lat, double lon)
    {
        // Zones approximatives des principales communes d'Abidjan
        // Plateau
        if (lat >= 5.32 && lat <= 5.34 && lon >= -4.03 && lon <= -4.01)
            return "Plateau";

        // Cocody
        if (lat >= 5.33 && lat <= 5.38 && lon >= -3.98 && lon <= -3.90)
            return "Cocody";

        // Yopougon
        if (lat >= 5.30 && lat <= 5.36 && lon >= -4.12 && lon <= -4.05)
            return "Yopougon";

        // Abobo
        if (lat >= 5.40 && lat <= 5.45 && lon >= -4.05 && lon <= -4.00)
            return "Abobo";

        // Adjamé
        if (lat >= 5.34 && lat <= 5.37 && lon >= -4.04 && lon <= -4.01)
            return "Adjamé";

        // Koumassi
        if (lat >= 5.28 && lat <= 5.32 && lon >= -3.96 && lon <= -3.92)
            return "Koumassi";

        // Marcory
        if (lat >= 5.28 && lat <= 5.31 && lon >= -4.01 && lon <= -3.98)
            return "Marcory";

        // Treichville
        if (lat >= 5.29 && lat <= 5.32 && lon >= -4.03 && lon <= -4.00)
            return "Treichville";

        // Port-Bouët
        if (lat >= 5.23 && lat <= 5.28 && lon >= -3.97 && lon <= -3.90)
            return "Port-Bouët";

        // Attécoubé
        if (lat >= 5.32 && lat <= 5.35 && lon >= -4.08 && lon <= -4.04)
            return "Attécoubé";

        // Par défaut : Abidjan
        return "Abidjan";
    }
}

/// <summary>
/// Réponse de l'API Overpass
/// </summary>
public class OverpassResponse
{
    [JsonPropertyName("version")]
    public double Version { get; set; }

    [JsonPropertyName("generator")]
    public string Generator { get; set; } = string.Empty;

    [JsonPropertyName("elements")]
    public List<OverpassElement> Elements { get; set; } = new();
}

/// <summary>
/// Élément retourné par Overpass (node ou way)
/// </summary>
public class OverpassElement
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("id")]
    public long Id { get; set; }

    [JsonPropertyName("lat")]
    public double? Lat { get; set; }

    [JsonPropertyName("lon")]
    public double? Lon { get; set; }

    [JsonPropertyName("center")]
    public OverpassCenter? Center { get; set; }

    [JsonPropertyName("tags")]
    public Dictionary<string, string>? Tags { get; set; }
}

/// <summary>
/// Centre d'un way (pour les bâtiments)
/// </summary>
public class OverpassCenter
{
    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lon")]
    public double Lon { get; set; }
}
