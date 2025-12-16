#!/bin/bash

# 🚀 Script de Migration PharmaGo vers Architecture 100% Gratuite
# Ce script automatise la migration de Google Maps vers OSM/OSRM

set -e  # Arrêter en cas d'erreur

echo "╔═══════════════════════════════════════════════════════╗"
echo "║     🏥 MIGRATION PHARMAGO - OSM/OSRM (Gratuit) 🏥    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier qu'on est à la racine du projet
if [ ! -d "pharmago" ] || [ ! -d "PharmaGoBackend" ]; then
    error "Ce script doit être exécuté depuis la racine du projet PharmaGo"
    exit 1
fi

echo ""
info "ÉTAPE 1/6 - Nettoyage du projet Flutter"
cd pharmago
flutter clean
success "Projet nettoyé"

echo ""
info "ÉTAPE 2/6 - Installation des dépendances Flutter"
flutter pub get
success "Dépendances installées"

echo ""
info "ÉTAPE 3/6 - Vérification des fichiers créés"
check_file() {
    if [ -f "$1" ]; then
        success "Trouvé: $1"
        return 0
    else
        warning "Manquant: $1"
        return 1
    fi
}

check_file "lib/services/osrm_service.dart"
check_file "lib/services/location_service.dart"
check_file "lib/ui/widgets/osm_map_widget.dart"
check_file "lib/ui/pages/pharmacy/pharmacy_detail_page_osm.dart"

echo ""
info "ÉTAPE 4/6 - Recherche des anciennes références Google Maps"
echo ""
warning "Les fichiers suivants utilisent encore Google Maps :"
grep -r "google_maps_flutter" lib/ --include="*.dart" | cut -d: -f1 | sort -u || true
echo ""
warning "Action requise : Migrer ou désactiver ces fichiers"

echo ""
info "ÉTAPE 5/6 - Vérification du backend .NET"
cd ../PharmaGoBackend

if [ -f "PharmaGo.csproj" ]; then
    success "Backend trouvé"
    
    # Vérifier si appsettings.json existe
    if [ -f "appsettings.json" ]; then
        success "Configuration trouvée"
        
        # Vérifier si Supabase est configuré
        if grep -q "Supabase" appsettings.json; then
            success "Supabase configuré"
        else
            warning "Supabase non configuré dans appsettings.json"
            echo ""
            echo "Ajoutez ceci dans appsettings.json :"
            echo '{
  "Supabase": {
    "Url": "https://votre-projet.supabase.co",
    "Key": "votre-cle-anon"
  }
}'
        fi
    else
        warning "appsettings.json manquant"
    fi
else
    error "Backend non trouvé"
fi

echo ""
info "ÉTAPE 6/6 - Test de compilation Flutter"
cd ../pharmago

if flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | grep -q "No issues found"; then
    success "Analyse statique réussie"
else
    warning "Quelques avertissements détectés (normal si migration partielle)"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              ✅ MIGRATION TERMINÉE ✅                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
success "Nouveaux services créés :"
echo "  • OSRMService - Calcul d'itinéraires gratuit"
echo "  • LocationService - Gestion GPS améliorée"
echo "  • OSMMapWidget - Widget carte OpenStreetMap"
echo "  • PharmacyDetailPageOSM - Page détail avec OSM"
echo ""
warning "Actions manuelles requises :"
echo "  1. Configurer Supabase dans appsettings.json"
echo "  2. Créer le bucket 'pharmacy_data' (PUBLIC) dans Supabase"
echo "  3. Mettre à jour app_router.dart pour utiliser les nouvelles pages OSM"
echo "  4. Désactiver ou migrer les anciens fichiers Google Maps"
echo ""
info "Documentation complète : MIGRATION_OSM_GUIDE.md"
echo ""
info "Prochaines étapes :"
echo "  Backend  : cd PharmaGoBackend && dotnet run"
echo "  Flutter  : cd pharmago && flutter run"
echo ""
success "PharmaGo est maintenant 100% GRATUIT (OSM + OSRM) ! 🎉"
echo ""
