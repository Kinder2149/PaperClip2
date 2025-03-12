import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_config.dart';
import 'crisis_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class CrisisAdapter {
  final CrisisService _crisisService;
  
  /// Constructeur
  CrisisAdapter(this._crisisService);
  
  /// Vérifie si le jeu est en mode crise (compatible avec l'ancien code)
  bool get isInCrisisMode => _crisisService.isInCrisisMode;
  
  /// Obtient la date de début de la crise (compatible avec l'ancien code)
  DateTime? get crisisStartTime => _crisisService.crisisStartTime;
  
  /// Vérifie si la transition vers le mode crise est terminée (compatible avec l'ancien code)
  bool get isCrisisTransitionComplete => _crisisService.isCrisisTransitionComplete;
  
  /// Déclenche le mode crise (compatible avec l'ancien code)
  Future<void> enterCrisisMode(BuildContext? context) async {
    await _crisisService.enterCrisisMode(context);
  }
  
  /// Gère la fin de partie en mode compétitif (compatible avec l'ancien code)
  Future<void> handleCompetitiveGameEnd() async {
    await _crisisService.handleCompetitiveGameEnd();
  }
  
  /// Vérifie si une crise doit être déclenchée (compatible avec l'ancien code)
  bool shouldTriggerCrisis(double marketMetalStock, GameMode gameMode) {
    return _crisisService.shouldTriggerCrisis(marketMetalStock, gameMode);
  }
  
  /// Obtient la durée de la crise (compatible avec l'ancien code)
  Duration getCrisisDuration() {
    return _crisisService.getCrisisDuration();
  }
  
  /// Vérifie si la crise est terminée (compatible avec l'ancien code)
  bool isCrisisOver() {
    return _crisisService.isCrisisOver();
  }
  
  /// Termine la crise (compatible avec l'ancien code)
  void endCrisis() {
    _crisisService.endCrisis();
  }
  
  /// Sauvegarde l'état de la crise (compatible avec l'ancien code)
  Map<String, dynamic> toJson() {
    return _crisisService.toJson();
  }
  
  /// Charge l'état de la crise (compatible avec l'ancien code)
  void fromJson(Map<String, dynamic> json) {
    _crisisService.fromJson(json);
  }
  
  /// Ajoute un écouteur pour les changements d'état de la crise (compatible avec l'ancien code)
  void addListener(VoidCallback listener) {
    _crisisService.addListener(listener);
  }
  
  /// Supprime un écouteur (compatible avec l'ancien code)
  void removeListener(VoidCallback listener) {
    _crisisService.removeListener(listener);
  }
} 