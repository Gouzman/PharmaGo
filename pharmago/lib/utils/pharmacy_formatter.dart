/// Utilitaire pour normaliser et formater les noms de pharmacies OSM
///
/// Corrige les problèmes courants :
/// - Noms sans le préfixe "Pharmacie"
/// - Descriptions mal formatées
/// - Adresses incomplètes ou mal structurées
class PharmacyFormatter {
  /// Normalise le nom d'une pharmacie
  ///
  /// Règles appliquées :
  /// 1. Ajoute "Pharmacie" si absent
  /// 2. Supprime les doublons de "Pharmacie"
  /// 3. Met en majuscule la première lettre
  /// 4. Nettoie les espaces multiples
  /// 5. Supprime les caractères spéciaux inutiles
  static String normalizeName(String rawName) {
    if (rawName.isEmpty) return 'Pharmacie';

    // Étape 1 : Nettoyer les espaces multiples et trim
    String cleaned = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Étape 1.5 : Supprimer les patterns OSM courants
    // Enlever "OSM" seul ou avec #
    cleaned = cleaned.replaceAll(
      RegExp(r'\s+OSM\s*#?\d*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\s+#\d+'),
      '',
    ); // Enlever les IDs type #9509792667

    // Étape 2 : Convertir en minuscules pour analyse
    String lower = cleaned.toLowerCase();

    // Étape 3 : Vérifier si "pharmacie" est déjà présent
    bool hasPharmaciePrefix = lower.startsWith('pharmacie');

    // Étape 4 : Supprimer les doublons de "pharmacie" (ex: "Pharmacie Pharmacie X")
    if (hasPharmaciePrefix) {
      cleaned = cleaned.replaceFirst(
        RegExp(r'^pharmacie\s+pharmacie\s+', caseSensitive: false),
        'Pharmacie ',
      );
    }

    // Étape 5 : Ajouter "Pharmacie" si absent
    if (!hasPharmaciePrefix) {
      cleaned = 'Pharmacie $cleaned';
    }

    // Étape 6 : Capitaliser correctement
    cleaned = _capitalizeWords(cleaned);

    // Étape 7 : Nettoyer les caractères spéciaux en début/fin
    cleaned = cleaned.replaceAll(RegExp(r'^[^\w\s]+|[^\w\s]+$'), '');

    // Étape 8 : Si le nom est juste "Pharmacie" (après nettoyage), retourner un nom par défaut
    if (cleaned.trim().toLowerCase() == 'pharmacie') {
      return 'Pharmacie';
    }

    return cleaned.trim();
  }

  /// Normalise une adresse
  ///
  /// Règles :
  /// - Supprime les espaces multiples
  /// - Capitalise les mots
  /// - Formate les numéros de rue
  static String normalizeAddress(String rawAddress) {
    if (rawAddress.isEmpty) return 'Adresse non renseignée';

    // Nettoyer les espaces multiples
    String cleaned = rawAddress.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Capitaliser les mots
    cleaned = _capitalizeWords(cleaned);

    return cleaned;
  }

  /// Normalise un nom de commune
  static String normalizeCommune(String rawCommune) {
    if (rawCommune.isEmpty) return 'Non renseignée';

    String cleaned = rawCommune.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _capitalizeWords(cleaned);
  }

  /// Normalise un nom de quartier
  static String normalizeQuartier(String rawQuartier) {
    if (rawQuartier.isEmpty) return 'Non renseigné';

    String cleaned = rawQuartier.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _capitalizeWords(cleaned);
  }

  /// Formate un numéro de téléphone
  ///
  /// Formats supportés :
  /// - +225 XX XX XX XX XX
  /// - 0X XX XX XX XX
  /// - XXXXXXXXXX (converti en format lisible)
  static String formatPhoneNumber(String rawPhone) {
    if (rawPhone.isEmpty) return 'Non renseigné';

    // Supprimer tous les caractères non numériques sauf le +
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) return 'Non renseigné';

    // Format international (+225)
    if (cleaned.startsWith('+225')) {
      String digits = cleaned.substring(4);
      if (digits.length == 10) {
        return '+225 ${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
      }
    }

    // Format local (10 chiffres)
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8, 10)}';
    }

    // Format local avec indicatif (8 chiffres)
    if (cleaned.length == 8) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)}';
    }

    return cleaned;
  }

  /// Capitalise la première lettre de chaque mot
  static String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;

          // Garder les acronymes en majuscules (ex: OSM, GPS)
          if (word.length <= 3 && word.toUpperCase() == word) {
            return word;
          }

          // Mots spéciaux à garder en minuscules (articles, prépositions)
          final lowercaseWords = {
            'de',
            'du',
            'des',
            'la',
            'le',
            'les',
            'à',
            'au',
            'aux',
            'et',
            'd\'',
            'l\'',
          };
          if (lowercaseWords.contains(word.toLowerCase())) {
            return word.toLowerCase();
          }

          // Capitaliser le premier caractère
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Détecte si un nom semble incomplet ou mal formaté
  static bool isNameMalformed(String name) {
    if (name.isEmpty) return true;

    final lower = name.toLowerCase().trim();

    // Trop court (moins de 3 caractères)
    if (lower.length < 3) return true;

    // Que des chiffres
    if (RegExp(r'^\d+$').hasMatch(lower)) return true;

    // Caractères spéciaux bizarres
    if (RegExp(r'[<>{}|\[\]\\]').hasMatch(lower)) return true;

    return false;
  }

  /// Détecte si une adresse semble incomplète
  static bool isAddressMalformed(String address) {
    if (address.isEmpty) return true;
    if (address.length < 5) return true;
    return false;
  }

  /// Génère un nom de fallback si le nom est invalide
  static String generateFallbackName(String commune, String quartier) {
    if (quartier.isNotEmpty && quartier != 'Non renseigné') {
      return 'Pharmacie $quartier';
    }
    if (commune.isNotEmpty && commune != 'Non renseignée') {
      return 'Pharmacie $commune';
    }
    return 'Pharmacie';
  }

  /// Détecte si une pharmacie est de garde basé sur son nom ou ses tags OSM
  ///
  /// Détection intelligente basée sur :
  /// - Présence de "garde" dans le nom
  /// - Tags OSM : dispensing=yes, emergency=yes
  /// - Mots-clés : 24/24, 24h, urgence, permanence
  static bool detectIsGuard({
    required String name,
    Map<String, dynamic>? osmTags,
  }) {
    final nameLower = name.toLowerCase();

    // Mots-clés indiquant une pharmacie de garde
    final guardKeywords = [
      'garde',
      '24/24',
      '24h',
      'h24',
      'urgence',
      'permanence',
      'nuit',
      'dimanche',
      'jour férié',
      'emergency',
    ];

    // Vérifier le nom
    for (final keyword in guardKeywords) {
      if (nameLower.contains(keyword)) {
        return true;
      }
    }

    // Vérifier les tags OSM si disponibles
    if (osmTags != null) {
      // Tag dispensing=yes indique souvent une pharmacie de garde
      if (osmTags['dispensing'] == 'yes') {
        return true;
      }

      // Tag emergency=yes
      if (osmTags['emergency'] == 'yes') {
        return true;
      }

      // Tag opening_hours avec pattern 24/7
      final openingHours = osmTags['opening_hours'] as String?;
      if (openingHours != null && openingHours.toLowerCase().contains('24/7')) {
        return true;
      }

      // Tag healthcare:speciality=emergency
      if (osmTags['healthcare:speciality'] == 'emergency') {
        return true;
      }
    }

    return false;
  }
}
