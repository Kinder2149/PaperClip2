import 'package:flutter/foundation.dart';

class Evenement {
  final DateTime date;
  final String type;
  final String description;
  final Map<String, dynamic> donnees;

  Evenement({
    required this.date,
    required this.type,
    required this.description,
    required this.donnees,
  });
}

class StatistiquesService extends ChangeNotifier {
  // Statistiques de production
  int _productionTotale = 0;
  double _productionCourante = 0;
  double _productionMaximale = 0;

  // Statistiques de marché
  double _prixMoyen = 0;
  double _prixMaximal = 0;
  double _prixCourant = 0;

  // Statistiques de ventes
  int _ventesTotales = 0;
  double _revenusTotal = 0;

  // Historique des événements
  List<Evenement> _historique = [];

  // Getters
  int get productionTotale => _productionTotale;
  double get productionCourante => _productionCourante;
  double get productionMaximale => _productionMaximale;
  double get prixMoyen => _prixMoyen;
  double get prixMaximal => _prixMaximal;
  double get prixCourant => _prixCourant;
  int get ventesTotales => _ventesTotales;
  double get revenusTotal => _revenusTotal;
  List<Evenement> get historique => _historique;

  // Méthodes de mise à jour
  void mettreAJourProduction(int production) {
    _productionTotale = production;
    double nouvelleProduction = production.toDouble() - _productionTotale;
    
    if (nouvelleProduction > 0) {
      _productionCourante = nouvelleProduction;
      if (nouvelleProduction > _productionMaximale) {
        _productionMaximale = nouvelleProduction;
        _ajouterEvenement(
          'production',
          'Nouveau record de production !',
          {'production': nouvelleProduction},
        );
      }
    }
    
    notifyListeners();
  }

  void mettreAJourPrix(double nouveauPrix) {
    _prixCourant = nouveauPrix;
    if (nouveauPrix > _prixMaximal) {
      _prixMaximal = nouveauPrix;
      _ajouterEvenement(
        'prix',
        'Nouveau record de prix !',
        {'prix': nouveauPrix},
      );
    }
    
    // Calculer la moyenne mobile
    _prixMoyen = (_prixMoyen * 9 + nouveauPrix) / 10;
    notifyListeners();
  }

  // Enregistrer une vente
  void enregistrerVente(int quantite, double prix) {
    _ventesTotales += quantite;
    double revenu = quantite * prix;
    _revenusTotal += revenu;
    
    _ajouterEvenement(
      'vente',
      'Vente de trombones',
      {
        'quantite': quantite,
        'prix': prix,
        'revenu': revenu,
      },
    );
    
    notifyListeners();
  }

  // Ajouter un événement à l'historique
  void _ajouterEvenement(String type, String description, Map<String, dynamic> donnees) {
    _historique.insert(
      0,
      Evenement(
        date: DateTime.now(),
        type: type,
        description: description,
        donnees: donnees,
      ),
    );
    
    // Limiter la taille de l'historique
    if (_historique.length > 50) {
      _historique.removeLast();
    }
    
    notifyListeners();
  }

  // Réinitialisation des statistiques
  void reinitialiser() {
    _productionTotale = 0;
    _productionCourante = 0;
    _productionMaximale = 0;
    _prixMoyen = 0;
    _prixMaximal = 0;
    _ventesTotales = 0;
    _revenusTotal = 0;
    _historique.clear();
    notifyListeners();
  }
} 