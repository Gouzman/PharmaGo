# 🚀 DÉMARRAGE RAPIDE - MIGRATION OSM

## ⚡ En 5 étapes

### 1️⃣ Vérifier la configuration

```bash
cd PharmaGoBackend
cat appsettings.json
```

Assurez-vous que `Supabase:Url` et `Supabase:Key` sont présents.

---

### 2️⃣ Compiler le projet

```bash
dotnet build
```

✅ Résultat attendu : `Build succeeded`

---

### 3️⃣ Lancer le backend

```bash
dotnet run
```

✅ La synchronisation OSM se déclenche automatiquement au démarrage !

---

### 4️⃣ Vérifier les logs

Cherchez dans les logs :

```
╔═══════════════════════════════════════════════════════╗
║     🗺️  SYNCHRONISATION OPENSTREETMAP → SUPABASE    ║
╚═══════════════════════════════════════════════════════╝
```

✅ Si vous voyez `✅ SYNCHRONISATION TERMINÉE`, c'est bon !

---

### 5️⃣ Tester l'API

```bash
# Récupérer l'URL du JSON
curl http://localhost:5000/api/pharmacies/latest

# Voir le contenu du JSON
curl [URL retournée]

# Forcer une nouvelle synchronisation OSM (optionnel)
curl -X POST http://localhost:5000/api/pharmacies/sync/osm
```

---

## 🎯 C'est tout !

Les pharmacies affichées dans l'app proviennent maintenant d'OpenStreetMap.

La synchronisation s'exécute automatiquement chaque jour à **3h du matin**.

---

## 📊 Vérification rapide

### Combien de pharmacies OSM ?

```bash
curl http://localhost:5000/api/pharmacies | jq '. | length'
```

### Voir les communes

```bash
curl http://localhost:5000/api/pharmacies | jq '[.[].commune] | unique'
```

### Voir une pharmacie

```bash
curl http://localhost:5000/api/pharmacies | jq '.[0]'
```

---

## 🐛 Problèmes ?

### Le backend ne démarre pas

```bash
# Vérifier les erreurs
dotnet build --verbosity detailed
```

### Aucune pharmacie récupérée

1. Vérifier votre connexion Internet
2. Tester manuellement Overpass API : https://overpass-turbo.eu/
3. Vérifier les logs backend

### Erreur Supabase

1. Vérifier `appsettings.json`
2. Créer le bucket `pharmacy_data` manuellement dans Supabase Dashboard
3. Vérifier que le bucket est **public**

---

## 📚 Documentation complète

Voir `GUIDE_MIGRATION_OSM.md` pour tous les détails techniques.

---

**Temps de mise en route** : ~2 minutes ⚡
