using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using HtmlAgilityPack;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Service de scraping du site officiel pharmacies-de-garde.ci
/// ⚠️ SCRAPING RESPECTUEUX : 1 requête / semaine MAX
/// </summary>
public class PharmaciesDeGardeScraperService
{
    private readonly HttpClient _httpClient;
    private const string BASE_URL = "https://www.pharmacies-de-garde.ci";
    
    public PharmaciesDeGardeScraperService()
    {
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Add("User-Agent", 
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
    }

    /// <summary>
    /// Récupère les pharmacies de garde depuis le site officiel
    /// </summary>
    public async Task<List<GuardPharmacyInfo>> FetchGuardPharmaciesAsync()
    {
        try
        {
            Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
            Console.WriteLine("║   🏥 SCRAPING PHARMACIES-DE-GARDE.CI (OFFICIEL)      ║");
            Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
            Console.WriteLine();
            Console.WriteLine("⚠️ ATTENTION : Sélecteurs HTML non validés");
            Console.WriteLine("💡 Le scraper retourne probablement 0 résultats");
            Console.WriteLine("🔧 Action requise : Inspecter le site et ajuster les sélecteurs");
            Console.WriteLine();

            var guardPharmacies = new List<GuardPharmacyInfo>();

            // Villes principales de Côte d'Ivoire
            var cities = new[] { "Abidjan", "Bouaké", "Daloa", "Yamoussoukro", "San-Pedro" };

            foreach (var city in cities)
            {
                Console.WriteLine($"📍 Scraping {city}...");
                
                // Délai pour éviter la détection
                await Task.Delay(Random.Shared.Next(2000, 4000));

                var cityPharmacies = await ScrapeCity(city);
                guardPharmacies.AddRange(cityPharmacies);

                if (cityPharmacies.Count == 0)
                {
                    Console.WriteLine($"   ⚠️ 0 pharmacie trouvée - Sélecteurs HTML probablement invalides");
                }
                else
                {
                    Console.WriteLine($"   ✅ {cityPharmacies.Count} pharmacie(s) de garde trouvée(s)");
                }
            }

            Console.WriteLine();
            if (guardPharmacies.Count == 0)
            {
                Console.WriteLine("❌ ÉCHEC TOTAL : 0 pharmacie de garde récupérée");
                Console.WriteLine("🔍 Causes possibles :");
                Console.WriteLine("   1. Sélecteurs CSS invalides");
                Console.WriteLine("   2. Structure HTML du site modifiée");
                Console.WriteLine("   3. Site nécessite JavaScript (HtmlAgilityPack ne supporte pas JS)");
                Console.WriteLine("   4. Blocage anti-scraping actif");
                Console.WriteLine();
                Console.WriteLine("💡 Solution : Vérifier le site manuellement et mettre à jour les sélecteurs");
            }
            else
            {
                Console.WriteLine($"🎯 TOTAL : {guardPharmacies.Count} pharmacie(s) de garde récupérée(s)");
            }
            Console.WriteLine();

            return guardPharmacies;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Erreur scraping pharmacies-de-garde.ci: {ex.Message}");
            Console.WriteLine($"🔍 Stack trace: {ex.StackTrace}");
            return new List<GuardPharmacyInfo>();
        }
    }

    /// <summary>
    /// Scrape les pharmacies de garde d'une ville spécifique
    /// </summary>
    private async Task<List<GuardPharmacyInfo>> ScrapeCity(string city)
    {
        try
        {
            var url = $"{BASE_URL}/pharmacies-de-garde/{city.ToLower()}";
            var html = await _httpClient.GetStringAsync(url);

            var doc = new HtmlDocument();
            doc.LoadHtml(html);

            var pharmacies = new List<GuardPharmacyInfo>();

            // 🔍 SÉLECTEURS CSS (À ADAPTER selon la structure réelle du site)
            // Ces sélecteurs sont des EXEMPLES - il faudra les ajuster après inspection du site
            var pharmacyNodes = doc.DocumentNode.SelectNodes("//div[@class='pharmacy-card']") 
                ?? doc.DocumentNode.SelectNodes("//article[@class='pharmacy']")
                ?? doc.DocumentNode.SelectNodes("//div[contains(@class, 'pharmacie')]");

            if (pharmacyNodes == null || pharmacyNodes.Count == 0)
            {
                // Tentative alternative : recherche par mots-clés
                var bodyText = doc.DocumentNode.InnerText;
                pharmacies.AddRange(ExtractFromText(bodyText, city));
                return pharmacies;
            }

            foreach (var node in pharmacyNodes)
            {
                var pharmacy = ExtractPharmacyFromNode(node, city);
                if (pharmacy != null)
                {
                    pharmacies.Add(pharmacy);
                }
            }

            return pharmacies;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"   ⚠️ Erreur scraping {city}: {ex.Message}");
            return new List<GuardPharmacyInfo>();
        }
    }

    /// <summary>
    /// Extrait les informations d'une pharmacie depuis un nœud HTML
    /// </summary>
    private GuardPharmacyInfo? ExtractPharmacyFromNode(HtmlNode node, string city)
    {
        try
        {
            // Extraction du nom (À ADAPTER)
            var nameNode = node.SelectSingleNode(".//h2[@class='pharmacy-name']") 
                ?? node.SelectSingleNode(".//h3")
                ?? node.SelectSingleNode(".//strong");
            
            var name = nameNode?.InnerText?.Trim();
            if (string.IsNullOrWhiteSpace(name))
                return null;

            // Extraction de l'adresse (À ADAPTER)
            var addressNode = node.SelectSingleNode(".//p[@class='address']") 
                ?? node.SelectSingleNode(".//span[contains(@class, 'adresse')]");
            
            var address = addressNode?.InnerText?.Trim() ?? "";

            // Extraction du téléphone (À ADAPTER)
            var phoneNode = node.SelectSingleNode(".//a[@class='phone']") 
                ?? node.SelectSingleNode(".//span[contains(@class, 'tel')]");
            
            var phone = phoneNode?.InnerText?.Trim() ?? "";

            // Extraction du quartier depuis l'adresse
            var quartier = ExtractQuartier(address);

            // Extraction des dates de garde (À ADAPTER)
            var guardPeriod = ExtractGuardPeriod(node);

            return new GuardPharmacyInfo
            {
                Name = CleanName(name),
                City = city,
                Address = address,
                Quartier = quartier,
                Phone = phone,
                GuardStart = guardPeriod.Start,
                GuardEnd = guardPeriod.End,
                Source = "pharmacies-de-garde.ci"
            };
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Extraction fallback depuis le texte brut (si pas de structure HTML)
    /// </summary>
    private List<GuardPharmacyInfo> ExtractFromText(string text, string city)
    {
        var pharmacies = new List<GuardPharmacyInfo>();

        // Regex pour trouver les pharmacies mentionnées
        var pharmacyPattern = @"(?i)pharmacie\s+([A-ZÀ-ÿ][a-zà-ÿ\s]+?)(?:\s*[-–]\s*|\s+)([A-ZÀ-ÿ][a-zà-ÿ\s]+?)";
        var matches = Regex.Matches(text, pharmacyPattern);

        foreach (Match match in matches)
        {
            var name = $"Pharmacie {match.Groups[1].Value.Trim()}";
            
            pharmacies.Add(new GuardPharmacyInfo
            {
                Name = CleanName(name),
                City = city,
                Address = match.Groups[2].Value.Trim(),
                Source = "pharmacies-de-garde.ci (text extraction)"
            });
        }

        return pharmacies;
    }

    /// <summary>
    /// Extrait la période de garde depuis un nœud HTML
    /// </summary>
    private (DateTime? Start, DateTime? End) ExtractGuardPeriod(HtmlNode node)
    {
        try
        {
            var dateText = node.SelectSingleNode(".//time")?.GetAttributeValue("datetime", "")
                ?? node.SelectSingleNode(".//span[@class='date']")?.InnerText
                ?? "";

            // Exemple : "Du 18/12/2025 au 24/12/2025"
            var datePattern = @"(\d{1,2}[/-]\d{1,2}[/-]\d{4}).*?(\d{1,2}[/-]\d{1,2}[/-]\d{4})";
            var match = Regex.Match(dateText, datePattern);

            if (match.Success)
            {
                var start = ParseDate(match.Groups[1].Value);
                var end = ParseDate(match.Groups[2].Value);
                return (start, end);
            }

            // Par défaut : garde de la semaine en cours
            var today = DateTime.UtcNow;
            var startOfWeek = today.AddDays(-(int)today.DayOfWeek);
            var endOfWeek = startOfWeek.AddDays(6);

            return (startOfWeek, endOfWeek);
        }
        catch
        {
            return (null, null);
        }
    }

    /// <summary>
    /// Parse une date au format français
    /// </summary>
    private DateTime? ParseDate(string dateStr)
    {
        try
        {
            var parts = dateStr.Split(new[] { '/', '-' });
            if (parts.Length != 3) return null;

            var day = int.Parse(parts[0]);
            var month = int.Parse(parts[1]);
            var year = int.Parse(parts[2]);

            return new DateTime(year, month, day);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Extrait le quartier depuis une adresse
    /// </summary>
    private string ExtractQuartier(string address)
    {
        // Quartiers connus d'Abidjan
        var knownQuartiers = new[] 
        { 
            "Cocody", "Plateau", "Marcory", "Yopougon", "Adjamé", 
            "Treichville", "Koumassi", "Abobo", "Attécoubé", "Port-Bouët",
            "Riviera", "Angré", "Bingerville", "Songon"
        };

        foreach (var quartier in knownQuartiers)
        {
            if (address.Contains(quartier, StringComparison.OrdinalIgnoreCase))
                return quartier;
        }

        return "";
    }

    /// <summary>
    /// Nettoie et normalise un nom de pharmacie
    /// </summary>
    private string CleanName(string name)
    {
        // Supprimer les caractères spéciaux et espaces multiples
        name = Regex.Replace(name, @"\s+", " ").Trim();
        
        // S'assurer que ça commence par "Pharmacie"
        if (!name.StartsWith("Pharmacie", StringComparison.OrdinalIgnoreCase))
        {
            name = $"Pharmacie {name}";
        }

        return name;
    }
}

/// <summary>
/// Informations d'une pharmacie de garde récupérée depuis le site
/// </summary>
public class GuardPharmacyInfo
{
    public string Name { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Quartier { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public DateTime? GuardStart { get; set; }
    public DateTime? GuardEnd { get; set; }
    public string Source { get; set; } = string.Empty;
}
