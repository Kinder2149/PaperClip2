import 'package:flutter/foundation.dart';
import 'dart:async';
import '../base/service_base.dart';
import '../ressources/gestionnaire_ressources.dart';

class GestionnaireProduction extends ServiceBase with ChangeNotifier {
  final GestionnaireRessources _gestionnaireRessources;
  Timer? _timerProduction;
  
  double _vitesseProduction = 1.0;
  double _multiplicateurProduction = 1.0;
  bool _productionAutomatique = false;
  
  GestionnaireProduction(this._gestionnaireRessources) {
    _demarrerProductionAutomatique();
  }

  // Getters
  double get vitesseProduction => _vitesseProduction;
  double get multiplicateurProduction => _multiplicateurProduction;
  bool get productionAutomatique => _productionAutomatique;

  // Méthodes de production
  void produire() {
    final production = _calculerProduction();
    _gestionnaireRessources.ajouterTrombones(production);
    logInfo('Production manuelle: $production trombones');
  }

  void _productionAutomatique() {
    if (!_productionAutomatique) return;
    final production = _calculerProduction();
    _gestionnaireRessources.ajouterTrombones(production);
    logInfo('Production automatique: $production trombones');
  }

  double _calculerProduction() {
    return _vitesseProduction * _multiplicateurProduction;
  }

  // Gestion de la production automatique
  void _demarrerProductionAutomatique() {
    _timerProduction?.cancel();
    _timerProduction = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _productionAutomatique(),
    );
  }

  void activerProductionAutomatique() {
    _productionAutomatique = true;
    logInfo('Production automatique activée');
    notifyListeners();
  }

  void desactiverProductionAutomatique() {
    _productionAutomatique = false;
    logInfo('Production automatique désactivée');
    notifyListeners();
  }

  // Améliorations
  void ameliorerVitesse(double montant) {
    if (montant <= 0) return;
    _vitesseProduction += montant;
    logInfo('Vitesse de production améliorée: $_vitesseProduction');
    notifyListeners();
  }

  void ameliorerMultiplicateur(double montant) {
    if (montant <= 0) return;
    _multiplicateurProduction += montant;
    logInfo('Multiplicateur de production amélioré: $_multiplicateurProduction');
    notifyListeners();
  }

  // Gestion de l'état
  void chargerEtat(Map<String, dynamic> etat) {
    _vitesseProduction = etat['vitesseProduction'] ?? 1.0;
    _multiplicateurProduction = etat['multiplicateurProduction'] ?? 1.0;
    _productionAutomatique = etat['productionAutomatique'] ?? false;
    logInfo('État de la production chargé');
    notifyListeners();
  }

  Map<String, dynamic> sauvegarderEtat() {
    return {
      'vitesseProduction': _vitesseProduction,
      'multiplicateurProduction': _multiplicateurProduction,
      'productionAutomatique': _productionAutomatique,
    };
  }

  // Nettoyage
  void dispose() {
    _timerProduction?.cancel();
    super.dispose();
  }
} 