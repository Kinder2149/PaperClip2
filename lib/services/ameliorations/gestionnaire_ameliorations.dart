import 'package:flutter/foundation.dart';
import '../base/service_base.dart';
import '../ressources/gestionnaire_ressources.dart';
import '../production/gestionnaire_production.dart';

class Amelioration {
  final String id;
  final String nom;
  final String description;
  final double coutBase;
  final double multiplicateurCout;
  final double valeurAmelioration;
  final String type;
  int niveau;
  bool debloque;

  Amelioration({
    required this.id,
    required this.nom,
    required this.description,
    required this.coutBase,
    required this.multiplicateurCout,
    required this.valeurAmelioration,
    required this.type,
    this.niveau = 0,
    this.debloque = false,
  });

  double getCoutNiveauSuivant() {
    return coutBase * (multiplicateurCout * niveau);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'niveau': niveau,
    'debloque': debloque,
  };

  factory Amelioration.fromJson(Map<String, dynamic> json, Amelioration base) {
    base.niveau = json['niveau'] ?? 0;
    base.debloque = json['debloque'] ?? false;
    return base;
  }
}

class GestionnaireAmeliorations extends ServiceBase with ChangeNotifier {
  final GestionnaireRessources _ressources;
  final GestionnaireProduction _production;
  final Map<String, Amelioration> _ameliorations = {};

  GestionnaireAmeliorations(this._ressources, this._production) {
    _initialiserAmeliorations();
  }

  // Getters
  List<Amelioration> get ameliorationsDisponibles => 
      _ameliorations.values.where((a) => a.debloque).toList();

  Amelioration? getAmeliorationParId(String id) => _ameliorations[id];

  void _initialiserAmeliorations() {
    // Améliorations de production
    _ajouterAmelioration(
      Amelioration(
        id: 'vitesse_production',
        nom: 'Vitesse de Production',
        description: 'Augmente la vitesse de production de trombones',
        coutBase: 10,
        multiplicateurCout: 1.5,
        valeurAmelioration: 0.5,
        type: 'production',
        debloque: true,
      ),
    );

    _ajouterAmelioration(
      Amelioration(
        id: 'multiplicateur_production',
        nom: 'Multiplicateur de Production',
        description: 'Multiplie la production de trombones',
        coutBase: 50,
        multiplicateurCout: 2.0,
        valeurAmelioration: 0.2,
        type: 'production',
        debloque: true,
      ),
    );

    // Améliorations de marché
    _ajouterAmelioration(
      Amelioration(
        id: 'prix_vente',
        nom: 'Prix de Vente',
        description: 'Augmente le prix de vente des trombones',
        coutBase: 100,
        multiplicateurCout: 1.8,
        valeurAmelioration: 0.1,
        type: 'marche',
      ),
    );
  }

  void _ajouterAmelioration(Amelioration amelioration) {
    _ameliorations[amelioration.id] = amelioration;
  }

  bool peutAcheter(String id) {
    final amelioration = _ameliorations[id];
    if (amelioration == null) return false;

    final cout = amelioration.getCoutNiveauSuivant();
    return _ressources.argent >= cout;
  }

  bool acheterAmelioration(String id) {
    final amelioration = _ameliorations[id];
    if (amelioration == null) {
      logError('Amélioration non trouvée: $id');
      return false;
    }

    final cout = amelioration.getCoutNiveauSuivant();
    if (_ressources.argent < cout) {
      logError('Pas assez d\'argent pour acheter l\'amélioration: $id');
      return false;
    }

    _ressources.retirerArgent(cout);
    amelioration.niveau++;

    // Appliquer l'effet de l'amélioration
    switch (amelioration.id) {
      case 'vitesse_production':
        _production.ameliorerVitesse(amelioration.valeurAmelioration);
        break;
      case 'multiplicateur_production':
        _production.ameliorerMultiplicateur(amelioration.valeurAmelioration);
        break;
    }

    logInfo('Amélioration achetée: ${amelioration.nom} (niveau ${amelioration.niveau})');
    notifyListeners();
    return true;
  }

  void debloquerAmelioration(String id) {
    final amelioration = _ameliorations[id];
    if (amelioration != null && !amelioration.debloque) {
      amelioration.debloque = true;
      logInfo('Amélioration débloquée: ${amelioration.nom}');
      notifyListeners();
    }
  }

  // Gestion de l'état
  void chargerEtat(Map<String, dynamic> etat) {
    final ameliorations = etat['ameliorations'] as Map<String, dynamic>?;
    if (ameliorations != null) {
      ameliorations.forEach((id, data) {
        final amelioration = _ameliorations[id];
        if (amelioration != null) {
          Amelioration.fromJson(data as Map<String, dynamic>, amelioration);
        }
      });
    }
    logInfo('État des améliorations chargé');
    notifyListeners();
  }

  Map<String, dynamic> sauvegarderEtat() {
    return {
      'ameliorations': Map.fromEntries(
        _ameliorations.entries.map(
          (e) => MapEntry(e.key, e.value.toJson()),
        ),
      ),
    };
  }
} 