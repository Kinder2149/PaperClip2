import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_config.dart';

/// Interface pour les services de gestion de crise
abstract class CrisisInterface {
  /// Vérifie si le jeu est en mode crise
  bool get isInCrisisMode;
  
  /// Obtient la date de début de la crise
  DateTime? get crisisStartTime;
  
  /// Vérifie si la transition vers le mode crise est terminée
  bool get isCrisisTransitionComplete;
  
  /// Déclenche le mode crise
  Future<void> enterCrisisMode(BuildContext? context);
  
  /// Gère la fin de partie en mode compétitif
  Future<void> handleCompetitiveGameEnd();
  
  /// Déverrouille les fonctionnalités du mode crise
  void unlockCrisisFeatures();
  
  /// Vérifie si une crise doit être déclenchée
  bool shouldTriggerCrisis(double marketMetalStock, GameMode gameMode);
  
  /// Obtient la durée de la crise
  Duration getCrisisDuration();
  
  /// Obtient le temps restant avant la fin de la crise
  Duration? getRemainingCrisisTime();
  
  /// Vérifie si la crise est terminée
  bool isCrisisOver();
  
  /// Termine la crise
  void endCrisis();
  
  /// Sauvegarde l'état de la crise
  Map<String, dynamic> toJson();
  
  /// Charge l'état de la crise
  void fromJson(Map<String, dynamic> json);
  
  /// Ajoute un écouteur pour les changements d'état de la crise
  void addListener(VoidCallback listener);
  
  /// Supprime un écouteur
  void removeListener(VoidCallback listener);
} 