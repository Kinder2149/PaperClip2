import 'package:flutter/foundation.dart';
import '../services/statistiques_service.dart';
import '../services/production_service.dart';
import '../services/marche_service.dart';
import '../services/ameliorations_service.dart';
import '../utils/constantes/jeu_constantes.dart';
import 'dart:async';

class JeuProvider extends ChangeNotifier {
  final StatistiquesService statistiques = StatistiquesService();
  final ProductionService production = ProductionService();
  final MarcheService marche = MarcheService();
  final AmeliorationsService ameliorations = AmeliorationsService();
  
  Timer? _timer;
  int _niveau = 1;
  double _experience = 0;
  double _experiencePourProchainNiveau = JeuConstantes.COUT_BASE_AMELIORATION;
  bool _productionAutomatiqueDebloquee = false;
  bool _marcheDebloque = false;
  bool _ameliorationsDebloquees = false;
  DateTime? _derniereSauvegarde;

  JeuProvider() {
    _initialiserTimers();
    _verifierDeblocages();
  }

  // Getters
  int get niveau => _niveau;
  double get experience => _experience;
  double get experiencePourProchainNiveau => _experiencePourProchainNiveau;
  double get progressionNiveau => _experience / _experiencePourProchainNiveau;
  bool get productionAutomatiqueDebloquee => _productionAutomatiqueDebloquee;
  bool get marcheDebloque => _marcheDebloque;
  bool get ameliorationsDebloquees => _ameliorationsDebloquees;
  DateTime? get derniereSauvegarde => _derniereSauvegarde;

  void _initialiserTimers() {
    // Timer pour la production automatique et les mises à jour
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (production.productionAutomatiqueActive) {
        production.mettreAJourProductionAutomatique();
      }
      marche.actualiserMarche();
      statistiques.mettreAJourProduction(production.trombonesProduits);
      statistiques.mettreAJourPrix(marche.prixCourant);
      _verifierDeblocages();
    });
  }

  void _verifierDeblocages() {
    // Débloquer la production automatique au niveau 2
    if (_niveau >= JeuConstantes.NIVEAU_DEBLOCAGE_PRODUCTION_AUTO && !_productionAutomatiqueDebloquee) {
      _productionAutomatiqueDebloquee = true;
      notifyListeners();
    }

    // Débloquer le marché au niveau 3
    if (_niveau >= JeuConstantes.NIVEAU_DEBLOCAGE_MARCHE && !_marcheDebloque) {
      _marcheDebloque = true;
      notifyListeners();
    }

    // Débloquer les améliorations au niveau 4
    if (_niveau >= JeuConstantes.NIVEAU_DEBLOCAGE_AMELIORATIONS && !_ameliorationsDebloquees) {
      _ameliorationsDebloquees = true;
      notifyListeners();
    }
  }

  // Actions du jeu
  void produireManuel() {
    production.produireManuel();
    _ajouterExperience(JeuConstantes.XP_PRODUCTION);
  }

  void vendreTrambones(int quantite) {
    if (quantite <= production.trombonesProduits) {
      double prixVente = marche.prixCourant;
      marche.vendreTrambones(quantite);
      production.reinitialiserCombo();
      statistiques.enregistrerVente(quantite, prixVente);
      _ajouterExperience(quantite * JeuConstantes.XP_VENTE);
      notifyListeners();
    }
  }

  bool acheterAmelioration(String id) {
    double cout = ameliorations.getCoutAmelioration(id);
    if (marche.acheter(cout)) {
      if (ameliorations.ameliorer(id)) {
        // Appliquer les effets de l'amélioration
        switch (id) {
          case 'prod_auto':
            production.ameliorerProductionAutomatique(1);
            break;
          case 'vitesse':
            production.ameliorerVitesse(JeuConstantes.BONUS_VITESSE);
            break;
          case 'efficacite':
            production.ameliorerEfficacite(JeuConstantes.BONUS_EFFICACITE);
            break;
        }
        _ajouterExperience(cout * JeuConstantes.XP_AMELIORATION);
        return true;
      }
    }
    return false;
  }

  void _ajouterExperience(double montant) {
    _experience += montant;
    while (_experience >= _experiencePourProchainNiveau) {
      _experience -= _experiencePourProchainNiveau;
      _niveau++;
      _experiencePourProchainNiveau *= JeuConstantes.MULTIPLICATEUR_XP_NIVEAU;
      _verifierDeblocages();
    }
    notifyListeners();
  }

  // Gestion de la production automatique
  void demarrerProductionAutomatique() {
    if (_productionAutomatiqueDebloquee) {
      production.demarrerProductionAutomatique();
    }
  }

  void arreterProductionAutomatique() {
    production.arreterProductionAutomatique();
  }

  // Sauvegarde et chargement
  Map<String, dynamic> sauvegarderEtat() {
    _derniereSauvegarde = DateTime.now();
    return {
      'niveau': _niveau,
      'experience': _experience,
      'experiencePourProchainNiveau': _experiencePourProchainNiveau,
      'productionAutomatiqueDebloquee': _productionAutomatiqueDebloquee,
      'marcheDebloque': _marcheDebloque,
      'ameliorationsDebloquees': _ameliorationsDebloquees,
      'production': {
        'trombonesProduits': production.trombonesProduits,
        'productionAutomatique': production.productionAutomatique,
        'bonusVitesse': production.bonusVitesse,
        'bonusEfficacite': production.bonusEfficacite,
      },
      'marche': {
        'argentDisponible': marche.argentDisponible,
        'prixCourant': marche.prixCourant,
        'trombonesVendus': marche.trombonesVendus,
      },
      'ameliorations': ameliorations.ameliorations.map(
        (id, a) => MapEntry(id, {'niveau': a.niveau, 'cout': a.cout}),
      ),
    };
  }

  void chargerEtat(Map<String, dynamic> etat) {
    _niveau = etat['niveau'] ?? 1;
    _experience = etat['experience'] ?? 0;
    _experiencePourProchainNiveau = etat['experiencePourProchainNiveau'] ?? JeuConstantes.COUT_BASE_AMELIORATION;
    _productionAutomatiqueDebloquee = etat['productionAutomatiqueDebloquee'] ?? false;
    _marcheDebloque = etat['marcheDebloque'] ?? false;
    _ameliorationsDebloquees = etat['ameliorationsDebloquees'] ?? false;

    // Charger l'état des services
    final productionEtat = etat['production'] ?? {};
    final marcheEtat = etat['marche'] ?? {};
    final ameliorationsEtat = etat['ameliorations'] ?? {};

    // Réinitialiser et recharger chaque service
    reinitialiserJeu();

    // Production
    for (int i = 0; i < (productionEtat['trombonesProduits'] ?? 0); i++) {
      production.produireManuel();
    }
    for (int i = 0; i < (productionEtat['productionAutomatique'] ?? 0); i++) {
      production.ameliorerProductionAutomatique(1);
    }

    // Marché
    for (int i = 0; i < (marcheEtat['trombonesVendus'] ?? 0); i++) {
      marche.vendreTrambones(1);
    }

    // Améliorations
    ameliorationsEtat.forEach((id, data) {
      for (int i = 0; i < (data['niveau'] ?? 0); i++) {
        ameliorations.ameliorer(id);
      }
    });

    notifyListeners();
  }

  // Réinitialisation du jeu
  void reinitialiserJeu() {
    statistiques.reinitialiser();
    production.reinitialiser();
    marche.reinitialiser();
    ameliorations.reinitialiser();
    _niveau = 1;
    _experience = 0;
    _experiencePourProchainNiveau = JeuConstantes.COUT_BASE_AMELIORATION;
    _productionAutomatiqueDebloquee = false;
    _marcheDebloque = false;
    _ameliorationsDebloquees = false;
    _derniereSauvegarde = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 