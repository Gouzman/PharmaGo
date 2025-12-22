# 🚨 Problèmes de Synchronisation - Diagnostic

## ⏰ Date
**20 décembre 2025**

---

## 📊 Résumé de la Synchronisation

```
✅ SYNCHRONISATION COMPLÈTE RÉUSSIE
⏱️  Durée : 624,4s
📊 OSM : 513 pharmacies
🏥 Garde : 0 pharmacies de garde             ❌ PROBLÈME
🔗 Matchés : 0                                ❌ PROBLÈME
```

---

## 🔴 Problèmes Identifiés

### 1. **Table `pharmacy_history` manquante** ❌ CRITIQUE

**Symptôme :**
```
⚠️ Erreur récupération historique: {"code":"PGRST205","details":null,"hint":"Perhaps you meant the table 'public.pharmacies'","message":"Could not find the table 'public.pharmacy_history' in the schema cache"}
⚠️ UpdateConfidenceScore désactivé (migration requise)
```

**Cause :**
- Le fichier SQL `supabase_migration_v2_history_confidence.sql` n'a **jamais été exécuté** sur Supabase
- La table `pharmacy_history` n'existe pas dans la base de données
- Les fonctions d'historique tentent d'y accéder et échouent silencieusement

**Impact :**
- ✅ **Pas de blocage** : Les erreurs sont catchées
- ⚠️ **Logs pollués** : Erreurs répétées à chaque pharmacie
- ❌ **Fonctionnalité perdue** : Pas d'historique des modifications

**✅ Solution Appliquée :**
Les méthodes suivantes ont été **désactivées** dans `SupabaseClientService.cs` :
- `InsertHistoryAsync()` → Return immédiat sans appel DB
- `GetPharmacyHistoryAsync()` → Retourne liste vide
- `GetHistoryNeedingReviewAsync()` → Retourne liste vide
- `UpdateConfidenceScoreAsync()` → Déjà désactivé

**🔧 Solution Définitive (à faire) :**
```bash
# Exécuter la migration SQL sur Supabase
supabase db push supabase_migration_v2_history_confidence.sql

# OU depuis l'interface Supabase :
# SQL Editor → Copier/coller le contenu du fichier → RUN
```

---

### 2. **0 pharmacies de garde récupérées** ❌ CRITIQUE

**Symptôme :**
```
🏥 Garde : 0 pharmacies de garde
🔗 Matchés : 0
```

**Cause :**
Le scraper `PharmaciesDeGardeScraperService` ne récupère **aucune pharmacie** depuis le site officiel `pharmacies-de-garde.ci`.

**Causes Probables :**

#### A. **Sélecteurs CSS Invalides**
Le code utilise des sélecteurs CSS **génériques** qui ne correspondent pas à la structure HTML réelle :

```csharp
// Sélecteurs actuels (PROBABLEMENT FAUX) :
var pharmacyNodes = doc.DocumentNode.SelectNodes("//div[@class='pharmacy-card']") 
    ?? doc.DocumentNode.SelectNodes("//article[@class='pharmacy']")
    ?? doc.DocumentNode.SelectNodes("//div[contains(@class, 'pharmacie')]");
```

**💡 Ces sélecteurs sont des EXEMPLES** - ils doivent être adaptés après inspection du site réel.

#### B. **Site Nécessite JavaScript**
- `HtmlAgilityPack` ne peut **pas exécuter JavaScript**
- Si le site charge les pharmacies dynamiquement via JS → **scraping impossible**
- Solution : Utiliser Selenium ou Playwright

#### C. **Blocage Anti-Scraping**
- Le site peut bloquer les requêtes automatisées
- User-Agent détecté comme bot
- Rate limiting activé

#### D. **Structure HTML Modifiée**
- Le site a peut-être changé sa structure HTML
- Les éléments portent des classes/IDs différents

---

**🔍 Diagnostic Recommandé :**

1. **Inspecter le site manuellement :**
   ```bash
   # Ouvrir dans le navigateur
   open https://www.pharmacies-de-garde.ci/pharmacies-de-garde/abidjan
   
   # Inspecter avec DevTools (Cmd+Option+I)
   # Identifier les vrais sélecteurs CSS
   ```

2. **Tester avec cURL :**
   ```bash
   curl -A "Mozilla/5.0" https://www.pharmacies-de-garde.ci/pharmacies-de-garde/abidjan > test.html
   open test.html
   # Vérifier si le HTML contient les pharmacies
   ```

3. **Ajouter des logs de debugging :**
   - ✅ **FAIT** : Logs améliorés dans `FetchGuardPharmaciesAsync()`
   - Prochain run affichera :
     ```
     ⚠️ ATTENTION : Sélecteurs HTML non validés
     💡 Le scraper retourne probablement 0 résultats
     🔧 Action requise : Inspecter le site et ajuster les sélecteurs
     ```

---

**✅ Solution Temporaire :**
Le système continue de fonctionner avec **uniquement les données OSM** (513 pharmacies).

**🔧 Solution Définitive (à faire) :**

1. **Inspecter le site** → Trouver les vrais sélecteurs CSS
2. **Mettre à jour** `PharmaciesDeGardeScraperService.cs` :
   ```csharp
   // Remplacer les sélecteurs par les VRAIS sélecteurs
   var pharmacyNodes = doc.DocumentNode.SelectNodes("//div[@class='VRAI_NOM']");
   ```
3. **Tester** le scraper isolément
4. **Relancer** la synchronisation

---

### 3. **0 matchs entre OSM et Garde** ℹ️ CONSÉQUENCE

**Cause :**
Si `guardPharmacies.Count == 0`, alors forcément `matched == 0`.

**Impact :**
Aucun - c'est une conséquence logique du problème #2.

---

## 📝 Actions Requises

### Priorité 1 : Migration SQL ⚡
```bash
# Exécuter sur Supabase
supabase db push supabase_migration_v2_history_confidence.sql
```

**OU** via l'interface Supabase :
1. Aller sur https://supabase.com/dashboard
2. Ouvrir votre projet
3. SQL Editor
4. Copier/coller le contenu de `supabase_migration_v2_history_confidence.sql`
5. **RUN**

### Priorité 2 : Fixer le Scraper 🔧

1. **Inspecter le site :**
   ```bash
   open https://www.pharmacies-de-garde.ci/pharmacies-de-garde/abidjan
   ```

2. **Identifier les vrais sélecteurs CSS**
   - Ouvrir DevTools (Cmd+Option+I)
   - Inspecter les éléments contenant les pharmacies
   - Noter les classes/IDs réels

3. **Mettre à jour le code** dans `PharmaciesDeGardeScraperService.cs`

4. **Tester** :
   ```bash
   dotnet run
   # OU
   curl http://localhost:5000/api/pharmacies/sync/full
   ```

### Priorité 3 : Réactiver l'Historique (après migration) ✅

Une fois la migration SQL exécutée, réactiver les méthodes dans `SupabaseClientService.cs` :
- `InsertHistoryAsync()`
- `GetPharmacyHistoryAsync()`
- `GetHistoryNeedingReviewAsync()`
- `UpdateConfidenceScoreAsync()`

---

## 🔄 Prochaine Synchronisation

**La prochaine synchronisation aura :**
- ✅ Plus d'erreurs liées à `pharmacy_history` (désactivé)
- ✅ Logs explicites sur le problème du scraper
- ❌ Toujours 0 pharmacies de garde (jusqu'à correction du scraper)

**Pour tester immédiatement :**
```bash
cd /Users/gouzman/Documents/pharma/PharmaGoBackend
dotnet run
```

---

## 📚 Fichiers Concernés

- ✅ `src/Infrastructure/SupabaseClientService.cs` (modifié)
- ✅ `src/Infrastructure/PharmaciesDeGardeScraperService.cs` (logs ajoutés)
- ⚠️ `supabase_migration_v2_history_confidence.sql` (non exécuté)

---

## 💡 Notes

- Le système **fonctionne** malgré ces problèmes
- Les 513 pharmacies OSM sont correctement synchronisées
- Le JSON est généré et uploadé avec succès
- L'application Flutter peut utiliser les données OSM

**C'est un problème de données manquantes, pas un blocage technique.**
