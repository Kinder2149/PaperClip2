import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class Evenement {
  final String id;
  final String titre;
  final String description;
  final Map<String, double> modificateurs;
  final Duration duree;
  final DateTime debut;

  Evenement({
    required this.id,
    required this.titre,
    required this.description,
    required this.modificateurs,
    required this.duree,
    required this.debut,
  });

  bool get estActif => DateTime.now().difference(debut) < duree;
}

class EvenementsService extends ChangeNotifier {
  final Random _random = Random();
  final List<Evenement> _evenementsActifs = [];
  Timer? _timerEvenements;
  final Function(String, String, String) onNotification;

  EvenementsService({required this.onNotification}) {
    _demarrerTimer();
  }

  List<Evenement> get evenementsActifs => _evenementsActifs;

  void _demarrerTimer() {
    _timerEvenements = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _verifierNouveauxEvenements(),
    );
  }

  void _verifierNouveauxEvenements() {
    if (_random.nextDouble() < 0.3) { // 30% de chance
      _declencherEvenementAleatoire();
    }
    _nettoyerEvenementsExpires();
  }

  void _declencherEvenementAleatoire() {
    final evenements = [
      _creerEvenementProductivite(),
      _creerEvenementMarche(),
      _creerEvenementBonus(),
      _creerEvenementDecouverte(),
    ];

    final evenement = evenements[_random.nextInt(evenements.length)];
    _evenementsActifs.add(evenement);

    onNotification(
      'Nouvel Événement !',
      evenement.titre,
      'info',
    );

    notifyListeners();
  }

  Evenement _creerEvenementProductivite() {
    final bonus = 1.0 + _random.nextDouble();
    return Evenement(
      id: 'productivite_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Pic de Productivité',
      description: 'Vos employés sont super motivés !',
      modificateurs: {'production': bonus},
      duree: Duration(minutes: 5 + _random.nextInt(10)),
      debut: DateTime.now(),
    );
  }

  Evenement _creerEvenementMarche() {
    final variation = 1.0 + _random.nextDouble() * 0.5;
    return Evenement(
      id: 'marche_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Tendance du Marché',
      description: 'Le marché est favorable aux ventes !',
      modificateurs: {'prix_vente': variation},
      duree: Duration(minutes: 3 + _random.nextInt(7)),
      debut: DateTime.now(),
    );
  }

  Evenement _creerEvenementBonus() {
    final bonus = 1.0 + _random.nextDouble() * 0.3;
    return Evenement(
      id: 'bonus_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Bonus Surprise',
      description: 'Un bonus mystérieux améliore tout !',
      modificateurs: {
        'production': bonus,
        'experience': bonus,
        'prix_vente': bonus,
      },
      duree: Duration(minutes: 2 + _random.nextInt(5)),
      debut: DateTime.now(),
    );
  }

  Evenement _creerEvenementDecouverte() {
    return Evenement(
      id: 'decouverte_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Découverte Technologique',
      description: 'Une nouvelle technologie améliore l\'efficacité !',
      modificateurs: {'efficacite': 1.5},
      duree: Duration(minutes: 15),
      debut: DateTime.now(),
    );
  }

  void _nettoyerEvenementsExpires() {
    _evenementsActifs.removeWhere((e) => !e.estActif);
    notifyListeners();
  }

  // Appliquer les modificateurs
  double appliquerModificateurs(String type, double valeur) {
    double multiplicateur = 1.0;
    for (var evenement in _evenementsActifs) {
      if (evenement.estActif && evenement.modificateurs.containsKey(type)) {
        multiplicateur *= evenement.modificateurs[type]!;
      }
    }
    return valeur * multiplicateur;
  }

  // Nettoyage
  void dispose() {
    _timerEvenements?.cancel();
    super.dispose();
  }

  // État pour sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'evenements': _evenementsActifs.map((e) => {
        'id': e.id,
        'titre': e.titre,
        'description': e.description,
        'modificateurs': e.modificateurs,
        'duree': e.duree.inMilliseconds,
        'debut': e.debut.millisecondsSinceEpoch,
      }).toList(),
    };
  }

  // Charger depuis sauvegarde
  void fromJson(Map<String, dynamic> json) {
    final evenements = (json['evenements'] as List?)?.map((e) => Evenement(
      id: e['id'],
      titre: e['titre'],
      description: e['description'],
      modificateurs: Map<String, double>.from(e['modificateurs']),
      duree: Duration(milliseconds: e['duree']),
      debut: DateTime.fromMillisecondsSinceEpoch(e['debut']),
    )).toList() ?? [];

    _evenementsActifs
      ..clear()
      ..addAll(evenements);
    
    notifyListeners();
  }
} 