import 'package:flutter/material.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:paperclip2/services/save/save_service.dart';
import 'sync_interface.dart';

/// Implémentation du service de synchronisation
class SyncService extends ChangeNotifier implements SyncInterface {
  bool _isSyncing = false;
  bool _lastSyncSuccessful = false;
  DateTime? _lastSyncTime;
  
  final SaveService _saveService;
  final GamesServicesController _gamesServices;
  
  /// Constructeur
  SyncService({
    required SaveService saveService,
    GamesServicesController? gamesServices,
  }) : 
    _saveService = saveService,
    _gamesServices = gamesServices ?? GamesServicesController();
  
  @override
  bool get isSyncing => _isSyncing;
  
  @override
  bool get lastSyncSuccessful => _lastSyncSuccessful;
  
  @override
  DateTime? get lastSyncTime => _lastSyncTime;
  
  @override
  Future<bool> sync() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Vérifier si l'utilisateur est connecté
      if (!await isSignedIn()) {
        _isSyncing = false;
        _lastSyncSuccessful = false;
        notifyListeners();
        return false;
      }
      
      // Synchroniser les différents composants
      final savesSynced = await syncSaves();
      final statsSynced = await syncStats();
      final achievementsSynced = await syncAchievements();
      final leaderboardsSynced = await syncLeaderboards();
      
      // Mettre à jour l'état
      _lastSyncTime = DateTime.now();
      _lastSyncSuccessful = savesSynced && statsSynced && achievementsSynced && leaderboardsSynced;
      _isSyncing = false;
      notifyListeners();
      
      return _lastSyncSuccessful;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
      _lastSyncSuccessful = false;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
  
  @override
  Future<bool> syncSaves() async {
    if (!await isSignedIn()) return false;
    
    try {
      return await _saveService.syncSaves();
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des sauvegardes: $e');
      return false;
    }
  }
  
  @override
  Future<bool> syncStats() async {
    if (!await isSignedIn()) return false;
    
    try {
      // Synchroniser les statistiques
      // Cette fonctionnalité pourrait être implémentée ultérieurement
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des statistiques: $e');
      return false;
    }
  }
  
  @override
  Future<bool> syncAchievements() async {
    if (!await isSignedIn()) return false;
    
    try {
      // Synchroniser les succès
      // Cette fonctionnalité pourrait être implémentée ultérieurement
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des succès: $e');
      return false;
    }
  }
  
  @override
  Future<bool> syncLeaderboards() async {
    if (!await isSignedIn()) return false;
    
    try {
      // Synchroniser les classements
      // Cette fonctionnalité pourrait être implémentée ultérieurement
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation des classements: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isSignedIn() async {
    return await _gamesServices.isSignedIn();
  }
  
  @override
  Future<bool> signIn() async {
    return await _gamesServices.signIn();
  }
  
  @override
  void showSyncNotification(BuildContext context, {required bool success, String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? (success ? 'Synchronisation réussie' : 'Échec de la synchronisation')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
} 