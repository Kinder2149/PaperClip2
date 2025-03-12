import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_state.dart';
import 'sync_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class SyncAdapter {
  final SyncService _syncService;
  
  /// Constructeur
  SyncAdapter(this._syncService);
  
  /// Synchronise les sauvegardes avec le cloud (compatible avec l'ancien code)
  Future<bool> syncSavesToCloud(GameState gameState, BuildContext? context) async {
    // Vérifier si l'utilisateur est connecté
    if (!await _syncService.isSignedIn()) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous à Google Play Games pour synchroniser'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    
    try {
      final result = await _syncService.syncSaves();
      
      if (context != null) {
        _syncService.showSyncNotification(
          context,
          success: result,
          message: result
              ? 'Synchronisation réussie'
              : 'Échec de la synchronisation',
        );
      }
      
      return result;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }
  
  /// Synchronise toutes les données (compatible avec l'ancien code)
  Future<bool> syncAll(BuildContext? context) async {
    // Vérifier si l'utilisateur est connecté
    if (!await _syncService.isSignedIn()) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous à Google Play Games pour synchroniser'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    
    try {
      final result = await _syncService.sync();
      
      if (context != null) {
        _syncService.showSyncNotification(
          context,
          success: result,
          message: result
              ? 'Synchronisation complète réussie'
              : 'Échec de la synchronisation complète',
        );
      }
      
      return result;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation complète: $e');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation complète: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }
  
  /// Vérifie si la synchronisation est en cours (compatible avec l'ancien code)
  bool get isSyncing => _syncService.isSyncing;
  
  /// Vérifie si la dernière synchronisation a réussi (compatible avec l'ancien code)
  bool get lastSyncSuccessful => _syncService.lastSyncSuccessful;
  
  /// Obtient la date de la dernière synchronisation (compatible avec l'ancien code)
  DateTime? get lastSyncTime => _syncService.lastSyncTime;
  
  /// Vérifie si l'utilisateur est connecté aux services de jeu (compatible avec l'ancien code)
  Future<bool> isSignedIn() async {
    return await _syncService.isSignedIn();
  }
  
  /// Se connecte aux services de jeu (compatible avec l'ancien code)
  Future<bool> signIn() async {
    return await _syncService.signIn();
  }
  
  /// Ajoute un écouteur pour les changements d'état de la synchronisation (compatible avec l'ancien code)
  void addListener(VoidCallback listener) {
    _syncService.addListener(listener);
  }
  
  /// Supprime un écouteur (compatible avec l'ancien code)
  void removeListener(VoidCallback listener) {
    _syncService.removeListener(listener);
  }
} 