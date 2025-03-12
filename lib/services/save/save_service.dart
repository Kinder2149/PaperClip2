import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/game_config.dart';
import 'package:paperclip2/models/event_system.dart';
import 'save_strategy.dart';
import 'local_save_strategy.dart';
import 'cloud_save_strategy.dart';

/// Service principal de sauvegarde qui utilise différentes stratégies
class SaveService extends ChangeNotifier {
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  static const int MAX_BACKUPS = 3;
  static const String BACKUP_PREFIX = 'backup_';
  
  /// Stratégie de sauvegarde locale
  final SaveStrategy _localStrategy;
  
  /// Stratégie de sauvegarde cloud (optionnelle)
  final SaveStrategy? _cloudStrategy;
  
  /// Timer pour la sauvegarde automatique
  Timer? _autoSaveTimer;
  
  /// Dernière sauvegarde automatique
  DateTime? _lastAutoSave;
  
  /// Compteur d'échecs de sauvegarde
  int _failedSaveAttempts = 0;
  static const int MAX_FAILED_ATTEMPTS = 3;
  
  /// Constructeur
  SaveService({
    SaveStrategy? localStrategy,
    SaveStrategy? cloudStrategy,
  }) : 
    _localStrategy = localStrategy ?? LocalSaveStrategy(),
    _cloudStrategy = cloudStrategy;
  
  /// Initialise le service
  void initialize() {
    _setupAutoSaveTimer();
  }
  
  /// Configure le timer de sauvegarde automatique
  void _setupAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(AUTO_SAVE_INTERVAL, (_) {
      debugPrint('Sauvegarde automatique...');
      // La sauvegarde automatique sera déclenchée par le jeu
    });
  }
  
  /// Sauvegarde les données du jeu
  Future<bool> saveGame(String name, Map<String, dynamic> data, {GameMode gameMode = GameMode.INFINITE}) async {
    try {
      // Sauvegarder localement
      final localSuccess = await _localStrategy.save(name, data, gameMode: gameMode);
      
      // Sauvegarder dans le cloud si disponible
      bool cloudSuccess = true;
      if (_cloudStrategy != null) {
        cloudSuccess = await _cloudStrategy!.save(name, data, gameMode: gameMode);
      }
      
      // Réinitialiser le compteur d'échecs en cas de succès
      if (localSuccess) {
        _failedSaveAttempts = 0;
        _lastAutoSave = DateTime.now();
        notifyListeners();
      } else {
        await _handleSaveError('LOCAL_SAVE_ERROR');
      }
      
      return localSuccess && cloudSuccess;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      await _handleSaveError(e.toString());
      return false;
    }
  }
  
  /// Charge les données du jeu
  Future<Map<String, dynamic>?> loadGame(String name) async {
    try {
      // Essayer de charger depuis le cloud d'abord si disponible
      if (_cloudStrategy != null) {
        final cloudData = await _cloudStrategy!.load(name);
        if (cloudData != null) {
          return cloudData;
        }
      }
      
      // Sinon, charger depuis le stockage local
      return await _localStrategy.load(name);
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      return null;
    }
  }
  
  /// Vérifie si une sauvegarde existe
  Future<bool> saveExists(String name) async {
    try {
      // Vérifier localement
      final localExists = await _localStrategy.exists(name);
      
      // Vérifier dans le cloud si disponible
      if (_cloudStrategy != null) {
        final cloudExists = await _cloudStrategy!.exists(name);
        return localExists || cloudExists;
      }
      
      return localExists;
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'existence: $e');
      return false;
    }
  }
  
  /// Supprime une sauvegarde
  Future<bool> deleteSave(String name) async {
    try {
      // Supprimer localement
      final localSuccess = await _localStrategy.delete(name);
      
      // Supprimer dans le cloud si disponible
      bool cloudSuccess = true;
      if (_cloudStrategy != null) {
        cloudSuccess = await _cloudStrategy!.delete(name);
      }
      
      notifyListeners();
      return localSuccess && cloudSuccess;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }
  
  /// Liste toutes les sauvegardes disponibles
  Future<List<SaveInfo>> listSaves() async {
    try {
      // Récupérer les sauvegardes locales
      final localSaves = await _localStrategy.listSaves();
      
      // Récupérer les sauvegardes cloud si disponible
      if (_cloudStrategy != null) {
        final cloudSaves = await _cloudStrategy!.listSaves();
        
        // Fusionner les listes en évitant les doublons
        final mergedSaves = <SaveInfo>[];
        final processedIds = <String>{};
        
        // Ajouter d'abord les sauvegardes cloud
        for (final cloudSave in cloudSaves) {
          mergedSaves.add(cloudSave);
          processedIds.add(cloudSave.id);
        }
        
        // Ajouter les sauvegardes locales qui ne sont pas déjà dans la liste
        for (final localSave in localSaves) {
          if (!processedIds.contains(localSave.id)) {
            mergedSaves.add(localSave);
          }
        }
        
        // Trier par date (plus récent d'abord)
        mergedSaves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return mergedSaves;
      }
      
      return localSaves;
    } catch (e) {
      debugPrint('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }
  
  /// Crée une sauvegarde de secours
  Future<bool> createBackup(String name, Map<String, dynamic> data) async {
    try {
      final backupName = '$BACKUP_PREFIX${name}_${DateTime.now().millisecondsSinceEpoch}';
      final success = await _localStrategy.save(backupName, data);
      
      if (success) {
        await _cleanupOldBackups();
      }
      
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la création du backup: $e');
      return false;
    }
  }
  
  /// Nettoie les anciennes sauvegardes de secours
  Future<void> _cleanupOldBackups() async {
    try {
      final saves = await _localStrategy.listSaves();
      final backups = saves.where((save) => save.name.startsWith(BACKUP_PREFIX)).toList();
      
      // Garder seulement les MAX_BACKUPS derniers backups
      if (backups.length > MAX_BACKUPS) {
        backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        for (var i = MAX_BACKUPS; i < backups.length; i++) {
          await _localStrategy.delete(backups[i].name);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des backups: $e');
    }
  }
  
  /// Gère les erreurs de sauvegarde
  Future<void> _handleSaveError(String error) async {
    _failedSaveAttempts++;
    
    if (_failedSaveAttempts >= MAX_FAILED_ATTEMPTS) {
      // Notifier l'utilisateur après plusieurs échecs
      EventManager.instance.addEvent(
        EventType.RESOURCE_DEPLETION,
        "Problème de sauvegarde",
        description: "Impossible de sauvegarder le jeu. Vérifiez l'espace de stockage.",
        importance: EventImportance.HIGH,
      );
      
      _failedSaveAttempts = 0;
    }
  }
  
  /// Récupère la dernière sauvegarde
  Future<SaveInfo?> getLastSave() async {
    final saves = await listSaves();
    return saves.isNotEmpty ? saves.first : null;
  }
  
  /// Synchronise les sauvegardes locales et cloud
  Future<bool> syncSaves() async {
    if (_cloudStrategy == null) {
      return false;
    }
    
    try {
      // Récupérer les sauvegardes locales et cloud
      final localSaves = await _localStrategy.listSaves();
      final cloudSaves = await _cloudStrategy!.listSaves();
      
      // Téléverser les sauvegardes locales qui ne sont pas dans le cloud
      for (final localSave in localSaves) {
        final matchingCloud = cloudSaves.where((cloud) => cloud.id == localSave.id).toList();
        
        if (matchingCloud.isEmpty || 
            (matchingCloud.isNotEmpty && localSave.timestamp.isAfter(matchingCloud.first.timestamp))) {
          // Charger les données complètes
          final data = await _localStrategy.load(localSave.name);
          if (data != null) {
            await _cloudStrategy!.save(localSave.name, data, gameMode: localSave.gameMode);
          }
        }
      }
      
      // Télécharger les sauvegardes cloud qui ne sont pas en local
      for (final cloudSave in cloudSaves) {
        final matchingLocal = localSaves.where((local) => local.id == cloudSave.id).toList();
        
        if (matchingLocal.isEmpty || 
            (matchingLocal.isNotEmpty && cloudSave.timestamp.isAfter(matchingLocal.first.timestamp))) {
          // Charger les données complètes
          final data = await _cloudStrategy!.load(cloudSave.name);
          if (data != null) {
            await _localStrategy.save(cloudSave.name, data, gameMode: cloudSave.gameMode);
          }
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
      return false;
    }
  }
  
  /// Récupère la date de la dernière sauvegarde automatique
  DateTime? get lastAutoSave => _lastAutoSave;
  
  /// Libère les ressources
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
} 