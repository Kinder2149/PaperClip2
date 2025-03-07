import 'package:flutter/foundation.dart';
import 'dart:math';
import '../utils/constantes/jeu_constantes.dart';

class MarcheService extends ChangeNotifier {
  double _argentDisponible = 0;
  double _prixCourant = JeuConstantes.PRIX_INITIAL;
  int _trombonesVendus = 0;
  double _prixMax = JeuConstantes.PRIX_INITIAL;
  double _prixMin = JeuConstantes.PRIX_INITIAL;
  List<double> _historiquePrix = [];
  DateTime _derniereMiseAJourPrix = DateTime.now();
  final Random _random = Random();

  // Getters
  double get argentDisponible => _argentDisponible;
  double get prixCourant => _prixCourant;
  int get trombonesVendus => _trombonesVendus;
  double get prixMax => _prixMax;
  double get prixMin => _prixMin;
  List<double> get historiquePrix => _historiquePrix;
  double get prixMoyen => _historiquePrix.isEmpty 
    ? _prixCourant 
    : _historiquePrix.reduce((a, b) => a + b) / _historiquePrix.length;

  // Vente de trombones
  void vendreTrambones(int quantite) {
    double revenu = quantite * _prixCourant;
    _argentDisponible += revenu;
    _trombonesVendus += quantite;
    _historiquePrix.add(_prixCourant);
    if (_historiquePrix.length > 50) {
      _historiquePrix.removeAt(0);
    }
    notifyListeners();
  }

  // Achat avec l'argent disponible
  bool acheter(double montant) {
    if (montant <= _argentDisponible) {
      _argentDisponible -= montant;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Mise à jour du prix du marché
  void actualiserMarche() {
    final maintenant = DateTime.now();
    if (maintenant.difference(_derniereMiseAJourPrix).inSeconds >= JeuConstantes.INTERVALLE_MAJ_PRIX) {
      _derniereMiseAJourPrix = maintenant;
      
      // Calculer la variation de prix
      double variation = 1.0 + (_random.nextDouble() * 0.4 - 0.2); // ±20%
      _prixCourant *= variation;

      // Limiter le prix dans les bornes
      _prixCourant = _prixCourant.clamp(
        JeuConstantes.PRIX_INITIAL * JeuConstantes.VARIATION_PRIX_MIN,
        JeuConstantes.PRIX_INITIAL * JeuConstantes.VARIATION_PRIX_MAX
      );

      // Mettre à jour les prix min/max
      if (_prixCourant > _prixMax) _prixMax = _prixCourant;
      if (_prixCourant < _prixMin) _prixMin = _prixCourant;

      notifyListeners();
    }
  }

  // Calcul du ROI (Return on Investment)
  double calculerROI(double cout, double productionParSeconde) {
    return cout / (productionParSeconde * _prixCourant);
  }

  // Réinitialisation
  void reinitialiser() {
    _argentDisponible = 0;
    _prixCourant = JeuConstantes.PRIX_INITIAL;
    _trombonesVendus = 0;
    _prixMax = JeuConstantes.PRIX_INITIAL;
    _prixMin = JeuConstantes.PRIX_INITIAL;
    _historiquePrix.clear();
    _derniereMiseAJourPrix = DateTime.now();
    notifyListeners();
  }
} 