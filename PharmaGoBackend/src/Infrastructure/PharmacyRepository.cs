using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using PharmaGo.Domain;

namespace PharmaGo.Infrastructure;

/// <summary>
/// Repository pour la gestion des pharmacies
/// </summary>
public class PharmacyRepository
{
    private readonly SupabaseClientService _supabaseClient;

    public PharmacyRepository(SupabaseClientService supabaseClient)
    {
        _supabaseClient = supabaseClient;
    }

    /// <summary>
    /// Récupère toutes les pharmacies
    /// </summary>
    public async Task<List<Pharmacy>> GetAllAsync()
    {
        return await _supabaseClient.GetPharmaciesAsync();
    }

    /// <summary>
    /// Récupère les pharmacies de garde actives
    /// </summary>
    public async Task<List<Pharmacy>> GetGuardPharmaciesAsync()
    {
        var allPharmacies = await GetAllAsync();
        return allPharmacies.Where(p => p.IsGuard).ToList();
    }

    /// <summary>
    /// Récupère une pharmacie par ID
    /// </summary>
    public async Task<Pharmacy?> GetByIdAsync(string id)
    {
        var allPharmacies = await GetAllAsync();
        return allPharmacies.FirstOrDefault(p => p.Id == id);
    }

    /// <summary>
    /// Récupère les pharmacies par commune
    /// </summary>
    public async Task<List<Pharmacy>> GetByCommuneAsync(string commune)
    {
        var allPharmacies = await GetAllAsync();
        return allPharmacies
            .Where(p => p.Commune.Equals(commune, StringComparison.OrdinalIgnoreCase))
            .ToList();
    }

    /// <summary>
    /// Récupère les pharmacies dans un rayon donné (en km)
    /// </summary>
    public async Task<List<Pharmacy>> GetNearbyAsync(double lat, double lng, double radiusKm)
    {
        var allPharmacies = await GetAllAsync();
        return allPharmacies
            .Where(p => CalculateDistance(lat, lng, p.Lat, p.Lng) <= radiusKm)
            .OrderBy(p => CalculateDistance(lat, lng, p.Lat, p.Lng))
            .ToList();
    }

    /// <summary>
    /// Calcule la distance entre deux points GPS (formule de Haversine)
    /// </summary>
    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371; // Rayon de la Terre en km

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private double ToRadians(double angle)
    {
        return Math.PI * angle / 180.0;
    }
}
