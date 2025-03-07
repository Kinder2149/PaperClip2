import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/etat_jeu.dart';
import '../utils/constantes/jeu_constantes.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ResultatValidation {
  final bool estValide;
  final List<String> erreurs;
  final Map<String, dynamic>? donneesValidees;

  ResultatValidation({
    required this.estValide,
    this.erreurs = const [],
    this.donneesValidees,
  });
}

class ValidateurDonneesSauvegarde {
  static const Map<String, Map<String, dynamic>> _reglesValidation = {
    'gestionnaireJoueur': {
      'argent': {'type': 'double', 'min': 0.0},
      'metal': {'type': 'double', 'min': 0.0},
      'trombones': {'type': 'double', 'min': 0.0},
      'autoclips': {'type': 'int', 'min': 0},
      'prixVente': {'type': 'double', 'min': 0.01, 'max': 1.0},
      'ameliorations': {'type': 'map'},
    },
    'gestionnaireMarche': {
      'stockMetalMarche': {'type': 'double', 'min': 0.0},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0},
      'dynamiques': {'type': 'map'},
    },
    'systemeNiveau': {
      'experience': {'type': 'double', 'min': 0.0},
      'niveau': {'type': 'int', 'min': 1},
      'cheminActuel': {'type': 'int', 'min': 0},
      'multiplicateurXP': {'type': 'double', 'min': 1.0},
    },
  };

  static ResultatValidation valider(Map<String, dynamic> donnees) {
    List<String> erreurs = [];

    // Vérification de base
    if (!donnees.containsKey('version') || !donnees.containsKey('horodatage')) {
      erreurs.add('Données de base manquantes (version ou horodatage)');
      return ResultatValidation(estValide: false, erreurs: erreurs);
    }

    // Vérification des données du joueur
    if (!donnees.containsKey('gestionnaireJoueur')) {
      erreurs.add('Données du joueur manquantes');
    } else {
      _validerSection(donnees['gestionnaireJoueur'], 'gestionnaireJoueur', erreurs);
    }

    // Vérification des données du marché
    if (!donnees.containsKey('gestionnaireMarche')) {
      erreurs.add('Données du marché manquantes');
    } else {
      _validerSection(donnees['gestionnaireMarche'], 'gestionnaireMarche', erreurs);
    }

    // Vérification des données de niveau
    if (!donnees.containsKey('systemeNiveau')) {
      erreurs.add('Données de niveau manquantes');
    } else {
      _validerSection(donnees['systemeNiveau'], 'systemeNiveau', erreurs);
    }

    return ResultatValidation(
      estValide: erreurs.isEmpty,
      erreurs: erreurs,
      donneesValidees: erreurs.isEmpty ? donnees : null,
    );
  }

  static void _validerSection(
    Map<String, dynamic> section,
    String nomSection,
    List<String> erreurs,
  ) {
    final regles = _reglesValidation[nomSection];
    if (regles == null) return;

    regles.forEach((champ, regle) {
      if (!section.containsKey(champ)) {
        erreurs.add('Champ $champ manquant dans $nomSection');
        return;
      }

      final valeur = section[champ];
      final type = regle['type'];

      switch (type) {
        case 'double':
          if (valeur is! num) {
            erreurs.add('$champ doit être un nombre');
          } else {
            final min = regle['min'] as double?;
            final max = regle['max'] as double?;
            if (min != null && valeur < min) {
              erreurs.add('$champ doit être >= $min');
            }
            if (max != null && valeur > max) {
              erreurs.add('$champ doit être <= $max');
            }
          }
          break;
        case 'int':
          if (valeur is! int) {
            erreurs.add('$champ doit être un entier');
          } else {
            final min = regle['min'] as int?;
            final max = regle['max'] as int?;
            if (min != null && valeur < min) {
              erreurs.add('$champ doit être >= $min');
            }
            if (max != null && valeur > max) {
              erreurs.add('$champ doit être <= $max');
            }
          }
          break;
        case 'map':
          if (valeur is! Map) {
            erreurs.add('$champ doit être un objet');
          }
          break;
      }
    });
  }
}

class SauvegardeJeu {
  final String id;
  final String nom;
  final DateTime derniereSauvegarde;
  final Map<String, dynamic> donneesJeu;
  final String version;
  bool estSynchroniseCloud;
  String? idCloud;
  ModeJeu modeJeu;

  SauvegardeJeu({
    String? id,
    required this.nom,
    required this.derniereSauvegarde,
    required this.donneesJeu,
    required this.version,
    this.estSynchroniseCloud = false,
    this.idCloud,
    ModeJeu? modeJeu,
  }) :
        id = id ?? const Uuid().v4(),
        modeJeu = modeJeu ?? (donneesJeu['modeJeu'] != null
            ? ModeJeu.values[donneesJeu['modeJeu'] as int]
            : ModeJeu.INFINI);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'nom': nom,
      'horodatage': derniereSauvegarde.toIso8601String(),
      'version': version,
      'estSynchroniseCloud': estSynchroniseCloud,
      'idCloud': idCloud,
      'modeJeu': modeJeu.index,
    };

    // Ajoute les données du jeu à la racine et dans donneesJeu
    if (donneesJeu.containsKey('gestionnaireJoueur')) {
      json['gestionnaireJoueur'] = donneesJeu['gestionnaireJoueur'];
    }
    if (donneesJeu.containsKey('gestionnaireMarche')) {
      json['gestionnaireMarche'] = donneesJeu['gestionnaireMarche'];
    }
    if (donneesJeu.containsKey('systemeNiveau')) {
      json['systemeNiveau'] = donneesJeu['systemeNiveau'];
    }

    // Sauvegarde complète des données
    json['donneesJeu'] = donneesJeu;

    return json;
  }

  factory SauvegardeJeu.fromJson(Map<String, dynamic> json) {
    try {
      // Si les données sont dans donneesJeu, utilise-les
      Map<String, dynamic> donneesJeu = json['donneesJeu'] as Map<String, dynamic>? ?? {};

      // Si les données sont à la racine, fusionne-les avec donneesJeu
      if (json.containsKey('gestionnaireJoueur')) {
        donneesJeu['gestionnaireJoueur'] = json['gestionnaireJoueur'];
      }
      if (json.containsKey('gestionnaireMarche')) {
        donneesJeu['gestionnaireMarche'] = json['gestionnaireMarche'];
      }
      if (json.containsKey('systemeNiveau')) {
        donneesJeu['systemeNiveau'] = json['systemeNiveau'];
      }

      // Déterminer le mode de jeu
      ModeJeu mode = ModeJeu.INFINI;
      if (json['modeJeu'] != null) {
        int indexMode = json['modeJeu'] as int;
        mode = ModeJeu.values[indexMode];
      } else if (donneesJeu['modeJeu'] != null) {
        int indexMode = donneesJeu['modeJeu'] as int;
        mode = ModeJeu.values[indexMode];
      }

      return SauvegardeJeu(
        id: json['id'] as String? ?? const Uuid().v4(),
        nom: json['nom'] as String,
        derniereSauvegarde: DateTime.parse(json['horodatage'] as String),
        donneesJeu: donneesJeu,
        version: json['version'] as String? ?? JeuConstantes.VERSION,
        estSynchroniseCloud: json['estSynchroniseCloud'] as bool? ?? false,
        idCloud: json['idCloud'] as String?,
        modeJeu: mode,
      );
    } catch (e) {
      print('Erreur lors de la création de SauvegardeJeu depuis JSON: $e');
      print('Données JSON: $json');
      rethrow;
    }
  }
}

class GestionnaireSauvegarde {
  static const String PREFIXE_SAUVEGARDE = 'paperclip_sauvegarde_';
  static final DateTime DATE_ACTUELLE = DateTime(2025, 1, 23, 15, 15, 49);
  static const String UTILISATEUR_ACTUEL = 'Kinder2149';
  static const String VERSION_ACTUELLE = '1.0.0';
  static const int TAILLE_CHUNK_COMPRESSION = 1024 * 512; // Chunks de 512KB
  static String _getCleSauvegarde(String nomPartie) => '$PREFIXE_SAUVEGARDE$nomPartie';

  // Sauvegarder une partie
  static Future<void> sauvegarderPartie(SauvegardeJeu sauvegarde) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cle = _getCleSauvegarde(sauvegarde.nom);
      await prefs.setString(cle, jsonEncode(sauvegarde.toJson()));
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  static bool _validationRapide(Map<String, dynamic> donnees) {
    return donnees.containsKey('gestionnaireJoueur') &&
        donnees.containsKey('gestionnaireMarche') &&
        donnees.containsKey('systemeNiveau');
  }

  static Future<InfoSauvegardeJeu?> getDerniereSauvegarde() async {
    final sauvegardes = await listerSauvegardes();
    return sauvegardes.isNotEmpty ? sauvegardes.first : null;
  }

  static Future<bool> sauvegardeExiste(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getCleSauvegarde(nom));
  }

  Future<String> compresserDonneesSauvegarde(Map<String, dynamic> donnees) async {
    final chaineJson = jsonEncode(donnees);
    final octets = utf8.encode(chaineJson);

    // Utiliser compute pour déplacer la compression sur un autre thread
    final compresse = await compute(_compresserOctets, octets);
    return base64Encode(compresse);
  }

  static List<int> _compresserOctets(List<int> entree) {
    return GZipEncoder().encode(entree) ?? [];
  }

  static Future<Map<String, dynamic>> decompresserDonneesSauvegarde(String compresse) async {
    final decode = base64Decode(compresse);
    final gzip = GZipCodec();
    final decompresse = gzip.decode(decode);
    final chaineJson = utf8.decode(decompresse);
    return jsonDecode(chaineJson);
  }

  static Future<bool> restaurerDepuisBackup(String nomBackup, EtatJeu etatJeu) async {
    try {
      final backup = await chargerPartie(nomBackup);
      if (backup == null) return false;

      // Créer un objet SauvegardeJeu avec les données actuelles du jeu
      final donneesActuelles = etatJeu.preparerDonneesJeu();
      final sauvegardeActuelle = SauvegardeJeu(
        nom: etatJeu.nomPartie!,
        derniereSauvegarde: DateTime.now(),
        donneesJeu: donneesActuelles,
        version: JeuConstantes.VERSION,
        modeJeu: etatJeu.modeJeu,
      );

      await sauvegarderPartie(sauvegardeActuelle);
      return true;
    } catch (e) {
      print('Erreur lors de la restauration: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> debugSauvegarde(String nom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleSauvegarde = _getCleSauvegarde(nom);
      final donneesSauvegardees = prefs.getString(cleSauvegarde);

      print('=== Debug Données Sauvegarde ===');
      print('Clé Sauvegarde: $cleSauvegarde');

      if (donneesSauvegardees == null) {
        print('Aucune sauvegarde trouvée pour: $nom');
        return null;
      }

      final donneesJson = jsonDecode(donneesSauvegardees) as Map<String, dynamic>;
      print('Version: ${donneesJson['version']}');
      print('Horodatage: ${donneesJson['horodatage']}');
      print('Contient gestionnaireJoueur: ${donneesJson.containsKey('gestionnaireJoueur')}');
      print('Contient donneesJeu: ${donneesJson.containsKey('donneesJeu')}');

      if (donneesJson.containsKey('gestionnaireJoueur')) {
        print('Structure données GestionnaireJoueur:');
        final donneesJoueur = donneesJson['gestionnaireJoueur'] as Map<String, dynamic>;
        donneesJoueur.forEach((cle, valeur) {
          print('  $cle: $valeur');
        });
      }

      print('=====================');
      return donneesJson;
    } catch (e) {
      print('Erreur debug sauvegarde: $e');
      print(e.toString());
      return null;
    }
  }

  static Future<List<InfoSauvegardeJeu>> listerSauvegardes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cles = prefs.getKeys().where((cle) => cle.startsWith(PREFIXE_SAUVEGARDE));
      final sauvegardes = <InfoSauvegardeJeu>[];

      for (var cle in cles) {
        final donnees = prefs.getString(cle);
        if (donnees != null) {
          try {
            final json = jsonDecode(donnees);
            final sauvegarde = SauvegardeJeu.fromJson(json);
            sauvegardes.add(InfoSauvegardeJeu(
              nom: sauvegarde.nom,
              horodatage: sauvegarde.derniereSauvegarde,
              version: sauvegarde.version,
              modeJeu: sauvegarde.modeJeu,
            ));
          } catch (e) {
            print('Erreur lors du décodage de la sauvegarde $cle: $e');
          }
        }
      }

      sauvegardes.sort((a, b) => b.horodatage.compareTo(a.horodatage));
      return sauvegardes;
    } catch (e) {
      print('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }

  static Future<SauvegardeJeu?> chargerPartie(String nom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donnees = prefs.getString(_getCleSauvegarde(nom));
      if (donnees == null) return null;

      final json = jsonDecode(donnees);
      return SauvegardeJeu.fromJson(json);
    } catch (e) {
      print('Erreur lors du chargement de la partie: $e');
      return null;
    }
  }

  static Future<void> supprimerSauvegarde(String nom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCleSauvegarde(nom));
    } catch (e) {
      print('Erreur lors de la suppression de la sauvegarde: $e');
      rethrow;
    }
  }
}

class InfoSauvegardeJeu {
  final String nom;
  final DateTime horodatage;
  final String version;
  final ModeJeu modeJeu;

  InfoSauvegardeJeu({
    required this.nom,
    required this.horodatage,
    required this.version,
    required this.modeJeu,
  });
}

class ErreurSauvegarde implements Exception {
  final String code;
  final String message;

  ErreurSauvegarde(this.code, this.message);

  @override
  String toString() => 'ErreurSauvegarde($code): $message';
} 