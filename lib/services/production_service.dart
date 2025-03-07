import 'package:flutter/foundation.dart';
import 'dart:async';

class ProductionService extends ChangeNotifier {
  int _trombonesProduits = 0;
  double _productionAutomatique = 0;
  bool _productionAutomatiqueActive = false;
  double _multiplicateurCombo = 1.0;
  double _comboActuel = 1.0;
  double _bonusVitesse = 0;
  double _bonusEfficacite = 1.0;
  Timer? _timer;

  // Getters
  int get trombonesProduits => _trombonesProduits;
  double get productionAutomatique => _productionAutomatique;
  bool get productionAutomatiqueActive => _productionAutomatiqueActive;
  double get multiplicateurCombo => _multiplicateurCombo;
  double get comboActuel => _comboActuel;
  double get bonusVitesse => _bonusVitesse;
  double get bonusEfficacite => _bonusEfficacite;

  // Production manuelle
  void produireManuel() {
    _trombonesProduits += (_multiplicateurCombo * _bonusEfficacite).round();
    _incrementerCombo();
    notifyListeners();
  }

  // Production automatique
  void demarrerProductionAutomatique() {
    _productionAutomatiqueActive = true;
    notifyListeners();
  }

  void arreterProductionAutomatique() {
    _productionAutomatiqueActive = false;
    notifyListeners();
  }

  void mettreAJourProductionAutomatique() {
    if (_productionAutomatiqueActive) {
      _trombonesProduits += (_productionAutomatique * _bonusEfficacite).round();
      notifyListeners();
    }
  }

  // Gestion du combo
  void _incrementerCombo() {
    _comboActuel++;
    _multiplicateurCombo = 1.0 + (_comboActuel * 0.1);
    if (_comboActuel > 10) {
      _multiplicateurCombo = 2.0;
    }
  }

  void reinitialiserCombo() {
    _comboActuel = 0;
    _multiplicateurCombo = 1.0;
    notifyListeners();
  }

  // Améliorations
  void ameliorerProductionAutomatique(double montant) {
    _productionAutomatique += montant;
    notifyListeners();
  }

  void ameliorerVitesse(double pourcentage) {
    _bonusVitesse += pourcentage;
    notifyListeners();
  }

  void ameliorerEfficacite(double pourcentage) {
    _bonusEfficacite *= (1 - pourcentage);
    notifyListeners();
  }

  // Réinitialisation
  void reinitialiser() {
    _trombonesProduits = 0;
    _productionAutomatique = 0;
    _productionAutomatiqueActive = false;
    _multiplicateurCombo = 1.0;
    _comboActuel = 0;
    _bonusVitesse = 0;
    _bonusEfficacite = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 