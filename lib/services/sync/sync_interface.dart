import 'package:flutter/material.dart';

/// Interface pour les services de synchronisation
abstract class SyncInterface {
  /// Vérifie si la synchronisation est en cours
  bool get isSyncing;
  
  /// Vérifie si la dernière synchronisation a réussi
  bool get lastSyncSuccessful;
  
  /// Obtient la date de la dernière synchronisation
  DateTime? get lastSyncTime;
  
  /// Synchronise les données entre les différents composants
  Future<bool> sync();
  
  /// Synchronise les sauvegardes avec le cloud
  Future<bool> syncSaves();
  
  /// Synchronise les statistiques avec le cloud
  Future<bool> syncStats();
  
  /// Synchronise les succès avec le cloud
  Future<bool> syncAchievements();
  
  /// Synchronise les classements avec le cloud
  Future<bool> syncLeaderboards();
  
  /// Vérifie si l'utilisateur est connecté aux services de jeu
  Future<bool> isSignedIn();
  
  /// Se connecte aux services de jeu
  Future<bool> signIn();
  
  /// Affiche une notification de synchronisation
  void showSyncNotification(BuildContext context, {required bool success, String? message});
  
  /// Ajoute un écouteur pour les changements d'état de la synchronisation
  void addListener(VoidCallback listener);
  
  /// Supprime un écouteur
  void removeListener(VoidCallback listener);
} 