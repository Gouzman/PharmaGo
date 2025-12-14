#!/bin/bash

# ===============================================================
# Script de déploiement PharmaGo Backend
# ===============================================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║         🚀 Déploiement PharmaGo Backend 🚀           ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Vérifier que .NET 8 est installé
if ! command -v dotnet &> /dev/null
then
    echo "❌ .NET 8 SDK n'est pas installé"
    echo "   Téléchargez-le sur: https://dotnet.microsoft.com/download/dotnet/8.0"
    exit 1
fi

echo "✅ .NET SDK détecté: $(dotnet --version)"
echo ""

# Nettoyer les builds précédents
echo "🧹 Nettoyage des builds précédents..."
dotnet clean
rm -rf bin obj publish

# Restaurer les packages
echo "📦 Restauration des packages NuGet..."
dotnet restore

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la restauration des packages"
    exit 1
fi

# Build du projet
echo "🔨 Build du projet..."
dotnet build -c Release

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du build"
    exit 1
fi

# Publish
echo "📤 Publication du projet..."
dotnet publish -c Release -o ./publish

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la publication"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              ✅ Déploiement réussi ! ✅              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "📁 Fichiers publiés dans: ./publish"
echo ""
echo "🚀 Pour démarrer le serveur:"
echo "   cd publish"
echo "   dotnet PharmaGo.dll"
echo ""
echo "📝 N'oubliez pas de configurer appsettings.json avec vos clés Supabase !"
echo ""
