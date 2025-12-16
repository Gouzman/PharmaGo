# 🚀 COMMANDES ESSENTIELLES - MIGRATION OSM

## 🔧 Développement

### Compiler le projet
```bash
cd PharmaGoBackend
dotnet build
```

### Lancer le backend
```bash
dotnet run
```

### Nettoyer et recompiler
```bash
dotnet clean
dotnet restore
dotnet build
```

---

## 🧪 Tests

### Tester la synchronisation automatique
```bash
./test_osm_sync.sh
```

### Vérifier l'API manuellement
```bash
# Statut du backend
curl http://localhost:5000/api/pharmacies/health

# URL du JSON
curl http://localhost:5000/api/pharmacies/latest

# Liste des pharmacies
curl http://localhost:5000/api/pharmacies | jq

# Nombre de pharmacies
curl http://localhost:5000/api/pharmacies | jq '. | length'

# Pharmacies de garde
curl http://localhost:5000/api/pharmacies/guard | jq
```

### Forcer la synchronisation OSM
```bash
curl -X POST http://localhost:5000/api/pharmacies/sync/osm
```

### Synchronisation complète
```bash
curl -X POST http://localhost:5000/api/pharmacies/sync
```

---

## 📊 Analyse des données

### Voir le contenu du JSON
```bash
# Récupérer l'URL
URL=$(curl -s http://localhost:5000/api/pharmacies/latest | jq -r '.url')

# Télécharger et afficher
curl -s "$URL" | jq
```

### Statistiques
```bash
# Nombre de pharmacies
curl -s "$URL" | jq '.pharmacies | length'

# Liste des communes
curl -s "$URL" | jq '[.pharmacies[].commune] | unique'

# Pharmacies OSM
curl -s "$URL" | jq '[.pharmacies[] | select(.id | startswith("osm_"))] | length'

# Exemple de pharmacie
curl -s "$URL" | jq '.pharmacies[0]'
```

---

## 🗺️ OpenStreetMap

### Tester la requête Overpass manuellement
Ouvrir https://overpass-turbo.eu/ et coller :

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

Cliquer sur **Exécuter**.

---

## 🔍 Logs et Debugging

### Voir les logs en temps réel
```bash
dotnet run --verbosity detailed
```

### Vérifier les erreurs de compilation
```bash
dotnet build --verbosity normal
```

### Inspecter la configuration
```bash
cat appsettings.json
```

---

## 📦 Supabase

### Créer le bucket manuellement
1. Ouvrir Supabase Dashboard
2. Aller dans **Storage**
3. Créer un bucket :
   - Nom : `pharmacy_data`
   - Public : **Oui**

### Vérifier le fichier JSON
URL :
```
https://[projet].supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json
```

---

## 🚢 Déploiement

### Déployer sur un serveur
```bash
# Publier le projet
dotnet publish -c Release -o ./publish

# Copier vers le serveur
scp -r ./publish user@server:/path/to/pharmago

# Sur le serveur
cd /path/to/pharmago
dotnet PharmaGo.dll
```

### Variables d'environnement
```bash
export Supabase__Url="https://[projet].supabase.co"
export Supabase__Key="[clé-anon]"
dotnet run
```

---

## ⏰ Planification

### Changer l'heure de synchronisation
Modifier `PharmacyUpdater.cs` :
```csharp
private readonly TimeSpan _targetTime = new TimeSpan(2, 0, 0); // 2h du matin
```

### Changer la fréquence
Actuellement : **1 fois par jour à 3h**

Pour modifier, voir `src/Cron/PharmacyUpdater.cs`

---

## 🐛 Troubleshooting

### Le backend ne démarre pas
```bash
# Vérifier les ports
lsof -i :5000

# Tuer le processus
kill -9 [PID]

# Relancer
dotnet run
```

### Erreur de compilation
```bash
# Nettoyer
dotnet clean

# Restaurer les packages
dotnet restore

# Recompiler
dotnet build
```

### Aucune pharmacie récupérée
1. Vérifier la connexion Internet
2. Tester Overpass API sur https://overpass-turbo.eu/
3. Consulter les logs backend

---

## 📚 Documentation

```bash
# Guide technique complet
cat GUIDE_MIGRATION_OSM.md

# Démarrage rapide
cat QUICK_START_OSM.md

# README
cat README_OSM.md
```

---

## 🎯 Quick Tests

### Test complet en une commande
```bash
# Démarrer le backend en arrière-plan
dotnet run &

# Attendre 10 secondes
sleep 10

# Tester
./test_osm_sync.sh

# Arrêter le backend
pkill -f "dotnet.*PharmaGo"
```

### One-liner pour vérifier que tout marche
```bash
curl -s http://localhost:5000/api/pharmacies/latest | jq -r '.url' | xargs curl -s | jq '.pharmacies | length'
```

---

## 📊 Monitoring

### Vérifier la santé de l'API
```bash
watch -n 5 'curl -s http://localhost:5000/api/pharmacies/health | jq'
```

### Surveiller les logs
```bash
dotnet run 2>&1 | tee pharmago.log
```

---

## 🎉 Commandes favorites

```bash
# Lancer le backend
dotnet run

# Forcer une synchro OSM
curl -X POST http://localhost:5000/api/pharmacies/sync/osm

# Tester tout
./test_osm_sync.sh

# Voir le JSON
curl -s $(curl -s http://localhost:5000/api/pharmacies/latest | jq -r '.url') | jq
```

---

**Astuce** : Enregistrer ces commandes dans votre `.bashrc` ou `.zshrc` :

```bash
alias pharmago-start="cd ~/Documents/pharma/PharmaGoBackend && dotnet run"
alias pharmago-test="~/Documents/pharma/test_osm_sync.sh"
alias pharmago-sync="curl -X POST http://localhost:5000/api/pharmacies/sync/osm"
alias pharmago-json="curl -s \$(curl -s http://localhost:5000/api/pharmacies/latest | jq -r '.url') | jq"
```

Puis :
```bash
pharmago-start    # Lancer le backend
pharmago-test     # Tester
pharmago-sync     # Forcer synchro
pharmago-json     # Voir le JSON
```
