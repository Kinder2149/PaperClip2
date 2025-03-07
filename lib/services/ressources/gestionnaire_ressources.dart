import 'package:flutter/foundation.dart';
import '../base/service_base.dart';

class GestionnaireRessources extends ServiceBase with ChangeNotifier {
  double _trombones = 0;
  double _argent = 0;
  double _fil = 0;
  bool _aFil = false;

  // Getters
  double get trombones => _trombones;
  double get argent => _argent;
  double get fil => _fil;
  bool get aFil => _aFil;

  // Méthodes de modification des ressources
  void ajouterTrombones(double montant) {
    if (montant <= 0) return;
    _trombones += montant;
    logInfo('Ajout de $montant trombones. Nouveau total: $_trombones');
    notifyListeners();
  }

  void retirerTrombones(double montant) {
    if (montant <= 0 || montant > _trombones) return;
    _trombones -= montant;
    logInfo('Retrait de $montant trombones. Nouveau total: $_trombones');
    notifyListeners();
  }

  void ajouterArgent(double montant) {
    if (montant <= 0) return;
    _argent += montant;
    logInfo('Ajout de $montant\$. Nouveau total: $_argent\$');
    notifyListeners();
  }

  void retirerArgent(double montant) {
    if (montant <= 0 || montant > _argent) return;
    _argent -= montant;
    logInfo('Retrait de $montant\$. Nouveau total: $_argent\$');
    notifyListeners();
  }

  void ajouterFil(double montant) {
    if (montant <= 0) return;
    _fil += montant;
    _aFil = true;
    logInfo('Ajout de $montant fil. Nouveau total: $_fil');
    notifyListeners();
  }

  void retirerFil(double montant) {
    if (montant <= 0 || montant > _fil) return;
    _fil -= montant;
    logInfo('Retrait de $montant fil. Nouveau total: $_fil');
    notifyListeners();
  }

  // Méthode pour réinitialiser l'état
  void reinitialiser() {
    _trombones = 0;
    _argent = 0;
    _fil = 0;
    _aFil = false;
    logInfo('Réinitialisation des ressources');
    notifyListeners();
  }

  // Méthode pour charger l'état
  void chargerEtat(Map<String, dynamic> etat) {
    _trombones = etat['trombones'] ?? 0;
    _argent = etat['argent'] ?? 0;
    _fil = etat['fil'] ?? 0;
    _aFil = etat['aFil'] ?? false;
    logInfo('État des ressources chargé');
    notifyListeners();
  }

  // Méthode pour sauvegarder l'état
  Map<String, dynamic> sauvegarderEtat() {
    return {
      'trombones': _trombones,
      'argent': _argent,
      'fil': _fil,
      'aFil': _aFil,
    };
  }
} 