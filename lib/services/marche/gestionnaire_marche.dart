import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../base/service_base.dart';
import '../ressources/gestionnaire_ressources.dart';

class GestionnaireMarche extends ServiceBase with ChangeNotifier {
  final GestionnaireRessources _gestionnaireRessources;
  Timer? _timerMarche;
  
  double _prixTrombone = 0.25;
  double _prixFil = 1.0;
  double _volatilite = 0.1;
  
  GestionnaireMarche(this._gestionnaireRessources) {
    _demarrerMiseAJourPrix();
  }

  // Getters
  double get prixTrombone => _prixTrombone;
  double get prixFil => _prixFil;

  // Méthodes de vente
  void vendreTrombones(int quantite) {
    if (quantite <= 0) return;
    if (_gestionnaireRessources.trombones < quantite) {
      logError('Pas assez de trombones disponibles');
      return;
    }

    final montantVente = quantite * _prixTrombone;
    _gestionnaireRessources.retirerTrombones(quantite.toDouble());
    _gestionnaireRessources.ajouterArgent(montantVente);
    
    // Ajuster le prix après la vente
    _ajusterPrixTrombone(-0.01 * quantite);
    
    logInfo('Vente de $quantite trombones pour \$$montantVente');
    notifyListeners();
  }

  void acheterFil(int quantite) {
    if (quantite <= 0) return;
    final coutTotal = quantite * _prixFil;
    
    if (_gestionnaireRessources.argent < coutTotal) {
      logError('Pas assez d\'argent disponible');
      return;
    }

    _gestionnaireRessources.retirerArgent(coutTotal);
    _gestionnaireRessources.ajouterFil(quantite.toDouble());
    
    // Ajuster le prix après l'achat
    _ajusterPrixFil(0.01 * quantite);
    
    logInfo('Achat de $quantite fil pour \$$coutTotal');
    notifyListeners();
  }

  // Gestion des prix
  void _demarrerMiseAJourPrix() {
    _timerMarche?.cancel();
    _timerMarche = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fluctuerPrix(),
    );
  }

  void _fluctuerPrix() {
    final random = Random();
    
    // Fluctuation aléatoire des prix
    _ajusterPrixTrombone((random.nextDouble() - 0.5) * _volatilite);
    _ajusterPrixFil((random.nextDouble() - 0.5) * _volatilite);
    
    notifyListeners();
  }

  void _ajusterPrixTrombone(double ajustement) {
    _prixTrombone = max(0.01, _prixTrombone + ajustement);
    logInfo('Nouveau prix trombone: \$$_prixTrombone');
  }

  void _ajusterPrixFil(double ajustement) {
    _prixFil = max(0.1, _prixFil + ajustement);
    logInfo('Nouveau prix fil: \$$_prixFil');
  }

  // Gestion de l'état
  void chargerEtat(Map<String, dynamic> etat) {
    _prixTrombone = etat['prixTrombone'] ?? 0.25;
    _prixFil = etat['prixFil'] ?? 1.0;
    _volatilite = etat['volatilite'] ?? 0.1;
    logInfo('État du marché chargé');
    notifyListeners();
  }

  Map<String, dynamic> sauvegarderEtat() {
    return {
      'prixTrombone': _prixTrombone,
      'prixFil': _prixFil,
      'volatilite': _volatilite,
    };
  }

  // Nettoyage
  void dispose() {
    _timerMarche?.cancel();
    super.dispose();
  }
} 