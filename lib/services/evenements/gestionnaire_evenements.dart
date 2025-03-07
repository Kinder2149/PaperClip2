import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../base/service_base.dart';
import '../ressources/gestionnaire_ressources.dart';
import '../production/gestionnaire_production.dart';
import '../marche/gestionnaire_marche.dart';
import '../ameliorations/gestionnaire_ameliorations.dart';

class Evenement {
  final String id;
  final String titre;
  final String description;
  final List<String> choix;
  final List<Function(GestionnaireEvenements)> consequences;
  final bool unique;
  bool estDeclenche;

  Evenement({
    required this.id,
    required this.titre,
    required this.description,
    required this.choix,
    required this.consequences,
    this.unique = false,
    this.estDeclenche = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'estDeclenche': estDeclenche,
  };

  factory Evenement.fromJson(Map<String, dynamic> json, Evenement base) {
    base.estDeclenche = json['estDeclenche'] ?? false;
    return base;
  }
}

class GestionnaireEvenements extends ServiceBase with ChangeNotifier {
  final GestionnaireRessources _ressources;
  final GestionnaireProduction _production;
  final GestionnaireMarche _marche;
  final GestionnaireAmeliorations _ameliorations;
  
  final Map<String, Evenement> _evenements = {};
  final List<Evenement> _evenementsActifs = [];
  Timer? _timerEvenements;
  
  GestionnaireEvenements(
    this._ressources,
    this._production,
    this._marche,
    this._ameliorations,
  ) {
    _initialiserEvenements();
    _demarrerVerificationEvenements();
  }

  // Getters
  List<Evenement> get evenementsActifs => List.unmodifiable(_evenementsActifs);

  void _initialiserEvenements() {
    // Événement : Découverte d'une nouvelle technique
    _ajouterEvenement(
      Evenement(
        id: 'nouvelle_technique',
        titre: 'Nouvelle Technique de Production',
        description: 'Vos travailleurs ont découvert une nouvelle technique de production !',
        choix: [
          'Adopter la technique (+20% production)',
          'Ignorer la découverte',
        ],
        consequences: [
          (GestionnaireEvenements ge) {
            ge._production.ameliorerVitesse(0.2);
          },
          (_) {},
        ],
        unique: true,
      ),
    );

    // Événement : Fluctuation du marché
    _ajouterEvenement(
      Evenement(
        id: 'fluctuation_marche',
        titre: 'Fluctuation du Marché',
        description: 'Le marché des trombones est instable !',
        choix: [
          'Vendre rapidement (-10% prix)',
          'Attendre que ça passe',
        ],
        consequences: [
          (GestionnaireEvenements ge) {
            final trombones = ge._ressources.trombones;
            ge._marche.vendreTrombones(trombones.toInt());
          },
          (_) {},
        ],
      ),
    );
  }

  void _ajouterEvenement(Evenement evenement) {
    _evenements[evenement.id] = evenement;
  }

  void _demarrerVerificationEvenements() {
    _timerEvenements?.cancel();
    _timerEvenements = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _verifierEvenements(),
    );
  }

  void _verifierEvenements() {
    if (_evenementsActifs.length >= 3) return;

    final random = Random();
    final evenementsDisponibles = _evenements.values.where((e) {
      if (e.unique && e.estDeclenche) return false;
      return !_evenementsActifs.contains(e);
    }).toList();

    if (evenementsDisponibles.isEmpty) return;

    if (random.nextDouble() < 0.3) {  // 30% de chance de déclencher un événement
      final evenement = evenementsDisponibles[random.nextInt(evenementsDisponibles.length)];
      declencherEvenement(evenement.id);
    }
  }

  void declencherEvenement(String id) {
    final evenement = _evenements[id];
    if (evenement == null) {
      logError('Événement non trouvé: $id');
      return;
    }

    if (!_evenementsActifs.contains(evenement)) {
      _evenementsActifs.add(evenement);
      logInfo('Événement déclenché: ${evenement.titre}');
      notifyListeners();
    }
  }

  void choisirOption(String evenementId, int indexChoix) {
    final evenement = _evenements[evenementId];
    if (evenement == null) {
      logError('Événement non trouvé: $evenementId');
      return;
    }

    if (indexChoix >= 0 && indexChoix < evenement.consequences.length) {
      evenement.consequences[indexChoix](this);
      evenement.estDeclenche = true;
      _evenementsActifs.remove(evenement);
      logInfo('Option choisie pour l\'événement ${evenement.titre}');
      notifyListeners();
    }
  }

  // Gestion de l'état
  void chargerEtat(Map<String, dynamic> etat) {
    _evenementsActifs.clear();
    
    final evenements = etat['evenements'] as Map<String, dynamic>?;
    if (evenements != null) {
      evenements.forEach((id, data) {
        final evenement = _evenements[id];
        if (evenement != null) {
          Evenement.fromJson(data as Map<String, dynamic>, evenement);
        }
      });
    }

    final actifs = etat['evenementsActifs'] as List<dynamic>?;
    if (actifs != null) {
      for (final id in actifs) {
        final evenement = _evenements[id as String];
        if (evenement != null) {
          _evenementsActifs.add(evenement);
        }
      }
    }

    logInfo('État des événements chargé');
    notifyListeners();
  }

  Map<String, dynamic> sauvegarderEtat() {
    return {
      'evenements': Map.fromEntries(
        _evenements.entries.map(
          (e) => MapEntry(e.key, e.value.toJson()),
        ),
      ),
      'evenementsActifs': _evenementsActifs.map((e) => e.id).toList(),
    };
  }

  // Nettoyage
  void dispose() {
    _timerEvenements?.cancel();
    super.dispose();
  }
} 