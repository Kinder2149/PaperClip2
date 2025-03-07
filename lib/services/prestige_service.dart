import 'package:flutter/foundation.dart';
import '../utils/constantes/jeu_constantes.dart';

class PrestigeService extends ChangeNotifier {
  int _niveau = 0;
  double _multiplicateurProduction = 1.0;
  double _multiplicateurExperience = 1.0;
  double _multiplicateurVente = 1.0;
  List<String> _avantagesDebloques = [];

  // Getters
  int get niveau => _niveau;
  double get multiplicateurProduction => _multiplicateurProduction;
  double get multiplicateurExperience => _multiplicateurExperience;
  double get multiplicateurVente => _multiplicateurVente;
  List<String> get avantagesDebloques => _avantagesDebloques;

  // Calcul des points de prestige disponibles
  int calculerPointsPrestige(int trombonesProduits, double argentTotal) {
    return (
      (trombonesProduits * 0.0001 + argentTotal * 0.001) *
      (1 + _niveau * 0.1)
    ).floor();
  }

  // Effectuer un prestige
  void effectuerPrestige(int points) {
    _niveau++;
    _multiplicateurProduction += points * 0.1;
    _multiplicateurExperience += points * 0.05;
    _multiplicateurVente += points * 0.05;
    
    // Débloquer des avantages selon le niveau
    _verifierDeblocages();
    
    notifyListeners();
  }

  // Vérifier les déblocages
  void _verifierDeblocages() {
    final nouveauxAvantages = <String>[];
    
    if (_niveau >= 1 && !_avantagesDebloques.contains('auto_vente')) {
      nouveauxAvantages.add('auto_vente');
    }
    if (_niveau >= 2 && !_avantagesDebloques.contains('auto_amelioration')) {
      nouveauxAvantages.add('auto_amelioration');
    }
    if (_niveau >= 3 && !_avantagesDebloques.contains('bonus_permanents')) {
      nouveauxAvantages.add('bonus_permanents');
    }
    
    if (nouveauxAvantages.isNotEmpty) {
      _avantagesDebloques.addAll(nouveauxAvantages);
    }
  }

  // Appliquer les bonus
  double appliquerBonusProduction(double valeur) {
    return valeur * _multiplicateurProduction;
  }

  double appliquerBonusExperience(double valeur) {
    return valeur * _multiplicateurExperience;
  }

  double appliquerBonusVente(double valeur) {
    return valeur * _multiplicateurVente;
  }

  // Réinitialisation
  void reinitialiser() {
    _niveau = 0;
    _multiplicateurProduction = 1.0;
    _multiplicateurExperience = 1.0;
    _multiplicateurVente = 1.0;
    _avantagesDebloques.clear();
    notifyListeners();
  }

  // État pour sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'niveau': _niveau,
      'multiplicateurProduction': _multiplicateurProduction,
      'multiplicateurExperience': _multiplicateurExperience,
      'multiplicateurVente': _multiplicateurVente,
      'avantagesDebloques': _avantagesDebloques,
    };
  }

  // Charger depuis sauvegarde
  void fromJson(Map<String, dynamic> json) {
    _niveau = json['niveau'] ?? 0;
    _multiplicateurProduction = json['multiplicateurProduction'] ?? 1.0;
    _multiplicateurExperience = json['multiplicateurExperience'] ?? 1.0;
    _multiplicateurVente = json['multiplicateurVente'] ?? 1.0;
    _avantagesDebloques = List<String>.from(json['avantagesDebloques'] ?? []);
    notifyListeners();
  }
} 