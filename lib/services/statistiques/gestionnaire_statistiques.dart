import 'package:flutter/foundation.dart';
import '../base/service_base.dart';

class StatistiqueJeu {
  final DateTime horodatage;
  final String type;
  final double valeur;
  final String? description;

  StatistiqueJeu({
    required this.horodatage,
    required this.type,
    required this.valeur,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'horodatage': horodatage.toIso8601String(),
    'type': type,
    'valeur': valeur,
    'description': description,
  };

  factory StatistiqueJeu.fromJson(Map<String, dynamic> json) => StatistiqueJeu(
    horodatage: DateTime.parse(json['horodatage']),
    type: json['type'],
    valeur: json['valeur'],
    description: json['description'],
  );
}

class GestionnaireStatistiques extends ServiceBase with ChangeNotifier {
  final List<StatistiqueJeu> _historique = [];
  final Map<String, double> _totaux = {};
  final Map<String, double> _records = {};

  // Getters
  List<StatistiqueJeu> get historique => List.unmodifiable(_historique);
  Map<String, double> get totaux => Map.unmodifiable(_totaux);
  Map<String, double> get records => Map.unmodifiable(_records);

  // Méthodes d'enregistrement
  void enregistrerEvenement({
    required String type,
    required double valeur,
    String? description,
  }) {
    final statistique = StatistiqueJeu(
      horodatage: DateTime.now(),
      type: type,
      valeur: valeur,
      description: description,
    );

    _historique.add(statistique);
    _mettreAJourTotaux(type, valeur);
    _verifierRecord(type, valeur);

    logInfo('Nouvel événement enregistré: $type - $valeur');
    notifyListeners();
  }

  void _mettreAJourTotaux(String type, double valeur) {
    _totaux[type] = (_totaux[type] ?? 0) + valeur;
  }

  void _verifierRecord(String type, double valeur) {
    if (!_records.containsKey(type) || valeur > _records[type]!) {
      _records[type] = valeur;
      logInfo('Nouveau record pour $type: $valeur');
    }
  }

  // Méthodes d'analyse
  double getMoyenne(String type) {
    final evenements = _historique.where((e) => e.type == type);
    if (evenements.isEmpty) return 0;
    
    final total = evenements.fold<double>(
      0,
      (sum, event) => sum + event.valeur,
    );
    return total / evenements.length;
  }

  List<StatistiqueJeu> getEvenementsParPeriode({
    required DateTime debut,
    required DateTime fin,
    String? type,
  }) {
    return _historique.where((e) {
      final dansLaPeriode = e.horodatage.isAfter(debut) && 
                           e.horodatage.isBefore(fin);
      return type != null 
          ? dansLaPeriode && e.type == type
          : dansLaPeriode;
    }).toList();
  }

  // Gestion de l'état
  void chargerEtat(Map<String, dynamic> etat) {
    _historique.clear();
    _totaux.clear();
    _records.clear();

    final historique = etat['historique'] as List<dynamic>;
    _historique.addAll(
      historique.map((e) => StatistiqueJeu.fromJson(e as Map<String, dynamic>)),
    );

    _totaux.addAll(Map<String, double>.from(etat['totaux']));
    _records.addAll(Map<String, double>.from(etat['records']));

    logInfo('État des statistiques chargé');
    notifyListeners();
  }

  Map<String, dynamic> sauvegarderEtat() {
    return {
      'historique': _historique.map((e) => e.toJson()).toList(),
      'totaux': _totaux,
      'records': _records,
    };
  }

  // Nettoyage
  void reinitialiser() {
    _historique.clear();
    _totaux.clear();
    _records.clear();
    logInfo('Statistiques réinitialisées');
    notifyListeners();
  }
} 