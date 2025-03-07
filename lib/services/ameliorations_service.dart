import 'package:flutter/foundation.dart';
import '../utils/constantes/jeu_constantes.dart';
import 'dart:math';

class Amelioration {
  final String id;
  final String nom;
  final String description;
  final String type;
  int niveau;
  double cout;

  Amelioration({
    required this.id,
    required this.nom,
    required this.description,
    required this.type,
    this.niveau = 0,
    required this.cout,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'description': description,
    'type': type,
    'niveau': niveau,
    'cout': cout,
  };

  factory Amelioration.fromJson(Map<String, dynamic> json) => Amelioration(
    id: json['id'],
    nom: json['nom'],
    description: json['description'],
    type: json['type'],
    niveau: json['niveau'],
    cout: json['cout'].toDouble(),
  );
}

class AmeliorationsService extends ChangeNotifier {
  final Map<String, Amelioration> _ameliorations = {
    'prod_auto': Amelioration(
      id: 'prod_auto',
      nom: 'Production Automatique',
      description: 'Augmente la production automatique de trombones',
      type: 'production',
      cout: 10.0,
    ),
    'vitesse': Amelioration(
      id: 'vitesse',
      nom: 'Vitesse de Production',
      description: 'Augmente la vitesse de production de tous les trombones',
      type: 'production',
      cout: 50.0,
    ),
    'efficacite': Amelioration(
      id: 'efficacite',
      nom: 'Efficacité de Production',
      description: 'Réduit les coûts de production',
      type: 'production',
      cout: 100.0,
    ),
  };

  // Getters
  Map<String, Amelioration> get ameliorations => _ameliorations;
  
  int get niveauProductionAuto => _ameliorations['prod_auto']?.niveau ?? 0;
  int get niveauVitesse => _ameliorations['vitesse']?.niveau ?? 0;
  int get niveauEfficacite => _ameliorations['efficacite']?.niveau ?? 0;

  double get coutProductionAuto => getCoutAmelioration('prod_auto');
  double get coutVitesse => getCoutAmelioration('vitesse');
  double get coutEfficacite => getCoutAmelioration('efficacite');

  // Méthodes
  double getCoutAmelioration(String id) {
    final amelioration = _ameliorations[id];
    if (amelioration == null) return double.infinity;
    return amelioration.cout * pow(1.5, amelioration.niveau);
  }

  bool ameliorer(String id) {
    final amelioration = _ameliorations[id];
    if (amelioration == null) return false;

    amelioration.niveau++;
    amelioration.cout *= 1.5;
    notifyListeners();
    return true;
  }

  void reinitialiser() {
    for (var amelioration in _ameliorations.values) {
      amelioration.niveau = 0;
      amelioration.cout = amelioration.id == 'prod_auto' ? 10.0 
                       : amelioration.id == 'vitesse' ? 50.0 
                       : 100.0;
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'ameliorations': _ameliorations.map((key, value) => MapEntry(key, value.toJson())),
  };

  void fromJson(Map<String, dynamic> json) {
    if (json['ameliorations'] != null) {
      final Map<String, dynamic> ameliorationsJson = json['ameliorations'];
      ameliorationsJson.forEach((key, value) {
        if (_ameliorations.containsKey(key)) {
          final amelioration = Amelioration.fromJson(value);
          _ameliorations[key]?.niveau = amelioration.niveau;
          _ameliorations[key]?.cout = amelioration.cout;
        }
      });
    }
    notifyListeners();
  }
}

// Fonction utilitaire pour calculer la puissance
double pow(double x, int n) {
  double result = 1;
  for (int i = 0; i < n; i++) {
    result *= x;
  }
  return result;
} 