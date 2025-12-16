# 🔧 CORRECTIONS APPORTÉES - ERREUR OVERPASS API

## ❌ Problème rencontré

```
❌ Erreur HTTP lors de la récupération OSM: Response status code does not indicate success: 400 (Bad Request).
```

L'API Overpass retournait une erreur 400, ce qui signifie que la requête était mal formatée.

---

## ✅ Corrections appliquées

### 1. **Format de la requête HTTP** ✅

**Avant** :
```csharp
new StringContent(query, System.Text.Encoding.UTF8, "application/x-www-form-urlencoded")
```

**Après** :
```csharp
var content = new FormUrlEncodedContent(new[]
{
    new KeyValuePair<string, string>("data", query)
});
```

**Raison** : L'API Overpass attend le paramètre `data` dans le corps de la requête POST.

---

### 2. **Simplification de la requête Overpass** ✅

**Avant** :
```
[out:json][timeout:60];
(
  node["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
  way["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
);
out center body;
>;
out skel qt;
```

**Après** :
```
[out:json][timeout:60];
(
  node["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
  way["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
);
out center body;
```

**Raison** : Suppression des lignes inutiles `>; out skel qt;` qui pouvaient causer des erreurs.

---

### 3. **Gestion des coordonnées pour les "way"** ✅

**Ajout** :
```csharp
// Déterminer les coordonnées (node direct ou centre d'un way)
double? lat = element.Lat;
double? lon = element.Lon;

// Si c'est un way (bâtiment), utiliser le centre
if ((!lat.HasValue || !lon.HasValue) && element.Center != null)
{
    lat = element.Center.Lat;
    lon = element.Center.Lon;
}
```

**Raison** : Les "way" (bâtiments) n'ont pas de coordonnées directes, il faut utiliser leur centre.

---

### 4. **Meilleure gestion d'erreur** ✅

**Ajout** :
```csharp
if (!response.IsSuccessStatusCode)
{
    var errorContent = await response.Content.ReadAsStringAsync();
    Console.WriteLine($"⚠️ Erreur Overpass API ({response.StatusCode}):");
    Console.WriteLine($"   {errorContent}");
    
    // Fallback avec GET si POST échoue
    if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
    {
        Console.WriteLine($"💡 Tentative avec GET...");
        var getUrl = $"{OverpassApiUrl}?data={Uri.EscapeDataString(query)}";
        var getResponse = await _httpClient.GetAsync(getUrl);
        
        if (getResponse.IsSuccessStatusCode)
        {
            response = getResponse;
        }
    }
}
```

**Raison** : Si POST échoue avec 400, on essaie avec GET en fallback.

---

### 5. **Ajout de debug** ✅

**Ajout** :
```csharp
Console.WriteLine($"📝 Requête Overpass:\n{query}");
```

**Raison** : Permet de voir exactement la requête envoyée pour déboguer.

---

### 6. **Méthodes statiques** ✅

Correction des méthodes helper pour être statiques :
- `BuildOverpassQuery()` ✅
- `BuildAddress()` ✅
- `CleanPhoneNumber()` ✅
- `DetermineCommune()` ✅

**Raison** : Optimisation et respect des bonnes pratiques.

---

### 7. **Gestion des exceptions** ✅

**Ajout** :
```csharp
catch (TaskCanceledException ex)
{
    Console.WriteLine($"❌ Timeout lors de la récupération OSM: {ex.Message}");
    Console.WriteLine($"💡 L'API Overpass met trop de temps à répondre, réessayez plus tard");
    throw;
}
```

**Raison** : Meilleure gestion des timeouts.

---

## 🧪 Tests à effectuer

### Test 1 : Vérifier la requête
```bash
dotnet run
```

Regarder dans les logs :
```
📝 Requête Overpass:
[out:json][timeout:60];
...
```

### Test 2 : Tester manuellement la requête

Sur https://overpass-turbo.eu/, coller :
```
[out:json][timeout:60];
(
  node["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
  way["amenity"="pharmacy"](5.20,-4.20,5.45,-3.90);
);
out center body;
```

Cliquer sur **Exécuter** et vérifier que ça fonctionne.

### Test 3 : Forcer la synchronisation
```bash
curl -X POST http://localhost:5000/api/pharmacies/sync/osm
```

---

## 📊 Résultat attendu

Si tout fonctionne, vous devriez voir dans les logs :

```
🔄 Récupération des pharmacies depuis OpenStreetMap...
📝 Requête Overpass:
[out:json][timeout:60];
...
✅ XX pharmacie(s) récupérée(s) depuis OSM
```

---

## 🐛 Si ça ne fonctionne toujours pas

### Option 1 : Problème de réseau
L'API Overpass peut être temporairement surchargée ou hors ligne.

**Solution** :
- Attendre quelques minutes
- Essayer un autre serveur Overpass :
  ```csharp
  private const string OverpassApiUrl = "https://overpass.kumi.systems/api/interpreter";
  ```

### Option 2 : Bounding box incorrecte
Les coordonnées d'Abidjan sont peut-être légèrement décalées.

**Solution** :
Tester sur https://overpass-turbo.eu/ et ajuster les coordonnées.

### Option 3 : Timeout
La requête prend trop de temps.

**Solution** :
Augmenter le timeout :
```csharp
_httpClient.Timeout = TimeSpan.FromMinutes(5);
```

---

## 📝 Fichiers modifiés

- ✅ `PharmaGoBackend/src/Infrastructure/OverpassService.cs`

---

## ✅ Checklist

- [x] Format de requête corrigé
- [x] Requête Overpass simplifiée
- [x] Gestion des "way" ajoutée
- [x] Gestion d'erreur améliorée
- [x] Debug ajouté
- [x] Méthodes statiques
- [x] Compilation réussie
- [ ] Test de synchronisation réussi

---

**Date** : 15 décembre 2025  
**Statut** : ✅ Corrigé, en attente de test
