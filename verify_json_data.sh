#!/bin/bash

# Script pour diagnostiquer les données des pharmacies
echo "📊 DIAGNOSTIC DES DONNÉES PHARMACIES"
echo "===================================="
echo ""

JSON_URL="https://wglrryhnrqninxzrmowh.supabase.co/storage/v1/object/public/pharmacy_data/pharmacies.json"

echo "🔍 Récupération des données..."
JSON_DATA=$(curl -s "$JSON_URL")

# Nombre total de pharmacies
TOTAL=$(echo "$JSON_DATA" | jq '.pharmacies | length')
echo "✅ Total pharmacies: $TOTAL"
echo ""

# Pharmacies avec téléphone
WITH_PHONE=$(echo "$JSON_DATA" | jq '[.pharmacies[] | select(.phone != "")] | length')
echo "📞 Avec téléphone: $WITH_PHONE ($((WITH_PHONE * 100 / TOTAL))%)"

# Pharmacies avec adresse
WITH_ADDRESS=$(echo "$JSON_DATA" | jq '[.pharmacies[] | select(.address != "")] | length')
echo "📍 Avec adresse: $WITH_ADDRESS ($((WITH_ADDRESS * 100 / TOTAL))%)"

# Pharmacies avec quartier
WITH_QUARTIER=$(echo "$JSON_DATA" | jq '[.pharmacies[] | select(.quartier != "")] | length')
echo "🏘️  Avec quartier: $WITH_QUARTIER ($((WITH_QUARTIER * 100 / TOTAL))%)"

# Pharmacies avec commune
WITH_COMMUNE=$(echo "$JSON_DATA" | jq '[.pharmacies[] | select(.commune != "")] | length')
echo "🌆 Avec commune: $WITH_COMMUNE ($((WITH_COMMUNE * 100 / TOTAL))%)"

# Pharmacies de garde
GUARD=$(echo "$JSON_DATA" | jq '[.pharmacies[] | select(.is_guard == true)] | length')
echo "🏥 De garde: $GUARD"

echo ""
echo "📋 Exemples de pharmacies AVEC données:"
echo "$JSON_DATA" | jq -r '.pharmacies[] | select(.phone != "" or .address != "") | "\(.name) - \(.commune) - \(.address) - \(.phone)"' | head -10

echo ""
echo "📋 Exemples de pharmacies SANS données:"
echo "$JSON_DATA" | jq -r '.pharmacies[] | select(.phone == "" and .address == "") | "\(.name) - \(.commune)"' | head -10

echo ""
echo "🎯 CONCLUSION:"
if [ $WITH_PHONE -lt 50 ]; then
    echo "⚠️  Très peu de pharmacies ont un numéro de téléphone renseigné dans OSM"
fi

if [ $WITH_ADDRESS -lt 100 ]; then
    echo "⚠️  Très peu de pharmacies ont une adresse détaillée dans OSM"
fi

echo ""
echo "💡 RECOMMANDATIONS:"
echo "   1. Les données OSM pour Abidjan sont incomplètes"
echo "   2. Flutter affiche correctement les données disponibles"
echo "   3. Solutions:"
echo "      - Enrichir OSM avec les données manquantes"
echo "      - Utiliser une autre source de données (scraping, API officielle)"
echo "      - Afficher uniquement les champs disponibles dans l'UI"
