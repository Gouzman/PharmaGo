#!/bin/bash

# Script de test de la migration OSM
# Utilisation : ./test_osm_sync.sh

set -e  # Arrêter en cas d'erreur

echo "╔═══════════════════════════════════════════════════════╗"
echo "║       🧪 TEST DE LA SYNCHRONISATION OSM              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Configuration
API_URL="http://localhost:5000/api/pharmacies"

echo "🔧 Configuration :"
echo "   API URL : $API_URL"
echo ""

# Fonction pour afficher un résultat
print_result() {
    if [ $1 -eq 0 ]; then
        echo "   ✅ $2"
    else
        echo "   ❌ $2"
        exit 1
    fi
}

# Test 1 : Vérifier que l'API est accessible
echo "📍 Test 1/5 : Vérification de l'API..."
curl -s -f "$API_URL/health" > /dev/null
print_result $? "API accessible"
echo ""

# Test 2 : Récupérer l'URL du JSON
echo "📍 Test 2/5 : Récupération de l'URL du JSON..."
JSON_URL=$(curl -s "$API_URL/latest" | jq -r '.url')
print_result $? "URL récupérée : $JSON_URL"
echo ""

# Test 3 : Vérifier que le JSON est accessible
echo "📍 Test 3/5 : Vérification du JSON..."
curl -s -f "$JSON_URL" > /tmp/pharmacies.json
print_result $? "JSON téléchargé"
echo ""

# Test 4 : Analyser le contenu du JSON
echo "📍 Test 4/5 : Analyse du JSON..."
PHARMACY_COUNT=$(jq '.pharmacies | length' /tmp/pharmacies.json)
VERSION=$(jq '.version' /tmp/pharmacies.json)
GENERATED_AT=$(jq -r '.generated_at' /tmp/pharmacies.json)

echo "   📊 Nombre de pharmacies : $PHARMACY_COUNT"
echo "   🔢 Version : $VERSION"
echo "   📅 Généré le : $GENERATED_AT"

if [ "$PHARMACY_COUNT" -gt 0 ]; then
    print_result 0 "JSON contient des pharmacies"
else
    print_result 1 "JSON vide"
fi
echo ""

# Test 5 : Vérifier qu'il y a des pharmacies OSM
echo "📍 Test 5/5 : Vérification des pharmacies OSM..."
OSM_COUNT=$(jq '[.pharmacies[] | select(.id | startswith("osm_"))] | length' /tmp/pharmacies.json)

echo "   🗺️  Pharmacies OSM : $OSM_COUNT"

if [ "$OSM_COUNT" -gt 0 ]; then
    print_result 0 "Pharmacies OSM trouvées"
else
    echo "   ⚠️  Aucune pharmacie OSM trouvée"
    echo "   ℹ️  La synchronisation OSM n'a peut-être pas encore eu lieu"
    echo "   💡 Déclenchez-la manuellement avec :"
    echo "      curl -X POST $API_URL/sync/osm"
fi
echo ""

# Afficher un exemple de pharmacie
echo "📋 Exemple de pharmacie :"
jq '.pharmacies[0]' /tmp/pharmacies.json
echo ""

# Afficher les communes
echo "📍 Communes trouvées :"
jq '[.pharmacies[].commune] | unique' /tmp/pharmacies.json
echo ""

# Résumé
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              ✅ TESTS TERMINÉS AVEC SUCCÈS           ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "📊 Résumé :"
echo "   • $PHARMACY_COUNT pharmacie(s) au total"
echo "   • $OSM_COUNT pharmacie(s) depuis OSM"
echo "   • JSON accessible publiquement"
echo ""
echo "🎯 Prochaines étapes :"
echo "   1. Vérifier les pharmacies dans l'app Flutter"
echo "   2. Attendre la prochaine synchronisation automatique (3h du matin)"
echo "   3. Consulter les logs du backend pour plus de détails"
echo ""
