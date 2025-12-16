using System;
using System.Globalization;

class TestOverpass
{
    static void Main()
    {
        const double MinLat = 5.20;
        const double MinLon = -4.20;
        const double MaxLat = 5.45;
        const double MaxLon = -3.90;

        // Test avec culture actuelle
        var query1 = $"[out:json][timeout:60];(node[amenity=pharmacy]({MinLat},{MinLon},{MaxLat},{MaxLon}););out center;";
        Console.WriteLine("Avec culture actuelle:");
        Console.WriteLine(query1);
        Console.WriteLine();

        // Test avec InvariantCulture
        var minLat = MinLat.ToString(CultureInfo.InvariantCulture);
        var minLon = MinLon.ToString(CultureInfo.InvariantCulture);
        var maxLat = MaxLat.ToString(CultureInfo.InvariantCulture);
        var maxLon = MaxLon.ToString(CultureInfo.InvariantCulture);

        var query2 = $"[out:json][timeout:60];(node[amenity=pharmacy]({minLat},{minLon},{maxLat},{maxLon}););out center;";
        Console.WriteLine("Avec InvariantCulture:");
        Console.WriteLine(query2);
    }
}
