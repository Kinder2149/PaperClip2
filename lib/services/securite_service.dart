import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuriteService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _cleSecrete = 'votre_cle_secrete_ici'; // À remplacer par une vraie clé
  
  // Vérification de l'intégrité des données
  bool verifierIntegrite(Map<String, dynamic> donnees, String checksum) {
    final calculatedChecksum = _genererChecksum(donnees);
    return calculatedChecksum == checksum;
  }

  // Génération de checksum
  String _genererChecksum(Map<String, dynamic> donnees) {
    final bytes = utf8.encode(jsonEncode(donnees) + _cleSecrete);
    return sha256.convert(bytes).toString();
  }

  // Détection de modifications suspectes
  bool detecterModificationsSuspectes({
    required int trombonesProduits,
    required double argentDisponible,
    required Duration tempsJeu,
    required Map<String, int> niveauxAmeliorations,
  }) {
    // Vérifier la cohérence des ressources
    if (_verifierProductionImpossible(trombonesProduits, tempsJeu)) {
      return true;
    }

    // Vérifier la cohérence de l'argent
    if (_verifierArgentImpossible(argentDisponible, trombonesProduits)) {
      return true;
    }

    // Vérifier la cohérence des améliorations
    if (_verifierAmeliorationsImpossibles(niveauxAmeliorations, argentDisponible)) {
      return true;
    }

    return false;
  }

  bool _verifierProductionImpossible(int trombones, Duration tempsJeu) {
    // Production maximale théorique par seconde
    const productionMaxParSeconde = 1000.0; // Ajuster selon votre jeu
    final productionMaxPossible = productionMaxParSeconde * tempsJeu.inSeconds;
    return trombones > productionMaxPossible;
  }

  bool _verifierArgentImpossible(double argent, int trombones) {
    // Prix de vente maximal théorique
    const prixMaxParTrombone = 100.0; // Ajuster selon votre jeu
    final argentMaxPossible = trombones * prixMaxParTrombone;
    return argent > argentMaxPossible;
  }

  bool _verifierAmeliorationsImpossibles(
    Map<String, int> niveaux,
    double argentTotal,
  ) {
    double coutTotal = 0;
    for (var niveau in niveaux.values) {
      // Coût théorique des améliorations
      coutTotal += _calculerCoutTotalAmelioration(niveau);
    }
    return coutTotal > argentTotal * 1.5; // Marge de 50%
  }

  double _calculerCoutTotalAmelioration(int niveau) {
    double cout = 10.0; // Coût de base
    double total = 0;
    for (int i = 0; i < niveau; i++) {
      total += cout;
      cout *= 1.5;
    }
    return total;
  }

  // Stockage sécurisé
  Future<void> sauvegarderSecurise(String cle, String valeur) async {
    await _storage.write(key: cle, value: valeur);
  }

  Future<String?> chargerSecurise(String cle) async {
    return await _storage.read(key: cle);
  }

  // Validation des actions
  bool validerAction({
    required String type,
    required Map<String, dynamic> parametres,
    required Map<String, dynamic> etatActuel,
  }) {
    switch (type) {
      case 'production':
        return _validerActionProduction(parametres, etatActuel);
      case 'vente':
        return _validerActionVente(parametres, etatActuel);
      case 'amelioration':
        return _validerActionAmelioration(parametres, etatActuel);
      default:
        return false;
    }
  }

  bool _validerActionProduction(
    Map<String, dynamic> parametres,
    Map<String, dynamic> etatActuel,
  ) {
    final quantite = parametres['quantite'] as int;
    final tempsEcoule = parametres['tempsEcoule'] as Duration;
    final productionParSeconde = etatActuel['productionParSeconde'] as double;

    return quantite <= productionParSeconde * tempsEcoule.inSeconds * 1.1;
  }

  bool _validerActionVente(
    Map<String, dynamic> parametres,
    Map<String, dynamic> etatActuel,
  ) {
    final quantite = parametres['quantite'] as int;
    final prix = parametres['prix'] as double;
    final trombonesDisponibles = etatActuel['trombones'] as int;

    return quantite <= trombonesDisponibles &&
           prix <= etatActuel['prixMaximal'] as double;
  }

  bool _validerActionAmelioration(
    Map<String, dynamic> parametres,
    Map<String, dynamic> etatActuel,
  ) {
    final cout = parametres['cout'] as double;
    final argentDisponible = etatActuel['argent'] as double;

    return cout <= argentDisponible;
  }
} 