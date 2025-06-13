// lib/services/api/save_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// Service de sauvegarde utilisant le backend personnalisé
/// Remplace les fonctionnalités de sauvegarde de Firebase Firestore et Storage
class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;

  // Client API et services
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();
  
  // Cache local des sauvegardes de profil
  final Map<String, Map<String, dynamic>> _profileSavesCache = {};
  bool _endpointAvailable = true;
  static const String _profileSavesCacheKey = 'profile_saves_cache';
  
  // Constructeur interne
  SaveService._internal();
  
  /// Initialisation du service
  Future<void> initialize() async {
    // Charger le cache local des sauvegardes de profil
    await _loadProfileSavesCache();
    debugPrint('SaveService initialisé');
  }
  
  /// Chargement du cache local des sauvegardes de profil
  Future<void> _loadProfileSavesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_profileSavesCacheKey);
      
      if (cacheJson != null) {
        final cache = json.decode(cacheJson);
        for (var entry in cache.entries) {
          _profileSavesCache[entry.key] = Map<String, dynamic>.from(entry.value);
        }
        debugPrint('Cache local des sauvegardes de profil chargé (${_profileSavesCache.length} entrées)');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du cache local des sauvegardes de profil: $e');
    }
  }
  
  /// Sauvegarde du cache local des sauvegardes de profil
  Future<void> _saveProfileSavesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = json.encode(_profileSavesCache);
      await prefs.setString(_profileSavesCacheKey, cacheJson);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du cache local des sauvegardes de profil: $e');
    }
  }
  
  /// Création d'une nouvelle sauvegarde
  Future<Map<String, dynamic>> createSave(
    Map<String, dynamic> saveData, {
    String? saveId,
    String? gameMode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'data': saveData,
        'game_mode': gameMode,
        'metadata': metadata ?? {},
      };
      
      if (saveId != null) {
        requestData['save_id'] = saveId;
      }
      
      final data = await _apiClient.post(
        '/saves',
        body: requestData,
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la création de la sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Mise à jour d'une sauvegarde existante
  Future<Map<String, dynamic>> updateSave(
    String saveId,
    Map<String, dynamic> saveData, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'data': saveData,
      };
      
      if (metadata != null) {
        requestData['metadata'] = metadata;
      }
      
      final data = await _apiClient.put(
        '/saves/$saveId',
        body: requestData,
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Récupération d'une sauvegarde
  Future<Map<String, dynamic>> getSave(String saveId) async {
    try {
      final data = await _apiClient.get('/saves/$saveId');
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Suppression d'une sauvegarde
  Future<bool> deleteSave(String saveId) async {
    try {
      await _apiClient.delete('/saves/$saveId');
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }
  
  /// Récupération des sauvegardes de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserSaves({String? gameMode}) async {
    try {
      final queryParams = <String, String>{};
      
      if (gameMode != null) {
        queryParams['game_mode'] = gameMode;
      }
      
      final data = await _apiClient.get(
        '/saves/user',
        queryParams: queryParams,
      );
      
      return List<Map<String, dynamic>>.from(data['saves'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sauvegardes de l\'utilisateur: $e');
      return [];
    }
  }
  
  /// Sauvegarde d'un fichier de sauvegarde
  Future<String> uploadSaveFile(File saveFile, String saveId) async {
    try {
      return await _storageService.uploadSave(saveFile, saveId);
    } catch (e) {
      debugPrint('Erreur lors de l\'upload du fichier de sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Téléchargement d'un fichier de sauvegarde
  Future<File> downloadSaveFile(String saveId) async {
    try {
      return await _storageService.downloadSave(saveId);
    } catch (e) {
      debugPrint('Erreur lors du téléchargement du fichier de sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Vérification de l'existence d'une sauvegarde
  Future<bool> saveExists(String saveId) async {
    try {
      final data = await _apiClient.get('/saves/$saveId/exists');
      
      return data['exists'] ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'existence de la sauvegarde: $e');
      return false;
    }
  }
  
  /// Création d'une sauvegarde locale
  Future<File> createLocalSaveFile(
    String saveId,
    Map<String, dynamic> saveData,
  ) async {
    try {
      // Obtenir le répertoire des documents
      final appDir = await getApplicationDocumentsDirectory();
      final savesDir = Directory(path.join(appDir.path, 'saves'));
      
      // Créer le répertoire s'il n'existe pas
      if (!await savesDir.exists()) {
        await savesDir.create(recursive: true);
      }
      
      // Créer le fichier de sauvegarde
      final saveFile = File(path.join(savesDir.path, '$saveId.save'));
      await saveFile.writeAsString(json.encode(saveData));
      
      return saveFile;
    } catch (e) {
      debugPrint('Erreur lors de la création du fichier de sauvegarde local: $e');
      rethrow;
    }
  }
  
  /// Chargement d'une sauvegarde locale
  Future<Map<String, dynamic>> loadLocalSaveFile(String saveId) async {
    try {
      // Obtenir le répertoire des documents
      final appDir = await getApplicationDocumentsDirectory();
      final savePath = path.join(appDir.path, 'saves', '$saveId.save');
      
      // Vérifier si le fichier existe
      final saveFile = File(savePath);
      if (!await saveFile.exists()) {
        throw Exception('Le fichier de sauvegarde n\'existe pas');
      }
      
      // Lire le fichier
      final saveContent = await saveFile.readAsString();
      
      return Map<String, dynamic>.from(json.decode(saveContent));
    } catch (e) {
      debugPrint('Erreur lors du chargement du fichier de sauvegarde local: $e');
      rethrow;
    }
  }
  
  /// Synchronisation d'une sauvegarde locale avec le serveur
  Future<bool> syncSaveToServer(String saveId) async {
    try {
      // Charger la sauvegarde locale
      final saveData = await loadLocalSaveFile(saveId);
      
      // Vérifier si la sauvegarde existe sur le serveur
      final exists = await saveExists(saveId);
      
      if (exists) {
        // Mettre à jour la sauvegarde
        await updateSave(saveId, saveData);
      } else {
        // Créer une nouvelle sauvegarde
        await createSave(saveData, saveId: saveId);
      }
      
      // Uploader le fichier de sauvegarde
      final appDir = await getApplicationDocumentsDirectory();
      final savePath = path.join(appDir.path, 'saves', '$saveId.save');
      final saveFile = File(savePath);
      
      await uploadSaveFile(saveFile, saveId);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation de la sauvegarde: $e');
      return false;
    }
  }
  
  /// Synchronisation d'une sauvegarde du serveur vers le local
  Future<bool> syncSaveFromServer(String saveId) async {
    try {
      // Récupérer la sauvegarde du serveur
      final saveData = await getSave(saveId);
      
      // Créer le fichier de sauvegarde local
      await createLocalSaveFile(saveId, saveData['data']);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation de la sauvegarde depuis le serveur: $e');
      return false;
    }
  }
  
  /// Synchronisation de toutes les sauvegardes
  Future<bool> syncAllSaves() async {
    try {
      // Récupérer les sauvegardes de l'utilisateur
      final saves = await getUserSaves();
      
      // Synchroniser chaque sauvegarde
      for (final save in saves) {
        final saveId = save['id'];
        await syncSaveFromServer(saveId);
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation de toutes les sauvegardes: $e');
      return false;
    }
  }
  
  /// Ajouter une sauvegarde au profil de l'utilisateur
  /// Utilise un cache local en cas d'indisponibilité du endpoint
  Future<Map<String, dynamic>> addSaveToProfile(
    String saveId,
    String gameMode, {
    Map<String, dynamic>? metadata,
  }) async {
    // Créer les données de sauvegarde pour le cache local
    final saveData = {
      'save_id': saveId,
      'game_mode': gameMode,
      'metadata': metadata ?? {},
      'added_at': DateTime.now().toIso8601String(),
      'synced': false
    };
    
    try {
      // Ne pas essayer d'appeler l'API si on sait déjà que l'endpoint est indisponible
      if (_endpointAvailable) {
        final response = await _apiClient.post(
          '/user/profile/saves',
          body: {
            'save_id': saveId,
            'game_mode': gameMode,
            'metadata': metadata ?? {},
          },
        );
        
        // Si la requête réussit, mettre à jour le cache local avec le statut synchronisé
        saveData['synced'] = true;
        _profileSavesCache[saveId] = saveData;
        await _saveProfileSavesCache();
        
        debugPrint('📥 Sauvegarde $saveId ajoutée au profil (via API)');
        return response;
      } else {
        // Endpoint indisponible, utilisation du cache local uniquement
        _profileSavesCache[saveId] = saveData;
        await _saveProfileSavesCache();
        
        debugPrint('📥 Sauvegarde $saveId ajoutée au profil (cache local seulement)');
        return {
          'success': true, 
          'message': 'Sauvegarde ajoutée localement (endpoint indisponible)',
          'local_only': true,
          'data': saveData
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de la sauvegarde au profil: $e');
      
      // Si c'est une erreur 404, marquer l'endpoint comme indisponible
      if (e.toString().contains('404')) {
        _endpointAvailable = false;
        debugPrint('⚠️ Endpoint /user/profile/saves indisponible, utilisation du cache local pour les futures requêtes');
      }
      
      // Sauvegarder quand même en local
      _profileSavesCache[saveId] = saveData;
      await _saveProfileSavesCache();
      
      return {
        'success': true, 
        'message': 'Sauvegarde ajoutée localement (endpoint indisponible)',
        'local_only': true,
        'error': e.toString(),
        'data': saveData
      };
    }
  }
  
  /// Retirer une sauvegarde du profil de l'utilisateur
  /// Utilise un cache local en cas d'indisponibilité du endpoint
  Future<Map<String, dynamic>> removeSaveFromProfile(
    String saveId, {
    bool deleteFile = false,
  }) async {
    try {
      // Supprimer du cache local
      _profileSavesCache.remove(saveId);
      await _saveProfileSavesCache();
      
      // Ne pas essayer d'appeler l'API si on sait déjà que l'endpoint est indisponible
      if (_endpointAvailable) {
        final queryParams = <String, String>{};
        
        if (deleteFile) {
          queryParams['delete_file'] = 'true';
        }
        
        final response = await _apiClient.delete(
          '/user/profile/saves/$saveId',
          queryParams: queryParams,
        );
        
        debugPrint('🗑️ Sauvegarde $saveId retirée du profil (via API)');
        return response;
      } else {
        // Endpoint indisponible, utilisation du cache local uniquement
        debugPrint('🗑️ Sauvegarde $saveId retirée du profil (cache local seulement)');
        return {
          'success': true, 
          'message': 'Sauvegarde retirée localement (endpoint indisponible)',
          'local_only': true
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du retrait de la sauvegarde du profil: $e');
      
      // Si c'est une erreur 404, marquer l'endpoint comme indisponible
      if (e.toString().contains('404')) {
        _endpointAvailable = false;
        debugPrint('⚠️ Endpoint /user/profile/saves indisponible, utilisation du cache local pour les futures requêtes');
      }
      
      // Supprimer quand même du cache local
      _profileSavesCache.remove(saveId);
      await _saveProfileSavesCache();
      
      return {
        'success': true, 
        'message': 'Sauvegarde retirée localement (endpoint indisponible)',
        'local_only': true,
        'error': e.toString()
      };
    }
  }
  
  /// Récupérer les sauvegardes du profil de l'utilisateur depuis le cache local
  Future<List<Map<String, dynamic>>> getUserProfileSaves() async {
    // Si API disponible, essayer de synchroniser d'abord
    await _attemptSyncProfileSaves();
    
    // Retourner du cache local
    return _profileSavesCache.values.toList();
  }
  
  /// Tentative de synchronisation des sauvegardes du profil
  /// Appelé périodiquement pour essayer de synchroniser avec le backend
  Future<bool> _attemptSyncProfileSaves() async {
    // Si l'endpoint est marqué comme indisponible, vérifier périodiquement s'il est de nouveau disponible
    if (!_endpointAvailable) {
      try {
        // Test pour voir si l'endpoint est de nouveau disponible
        await _apiClient.get('/user/profile/saves');
            
        // Si on arrive ici, l'endpoint est disponible
        _endpointAvailable = true;
        debugPrint('✅ Endpoint /user/profile/saves est maintenant disponible');
        
        // Synchroniser les données en cache
        await _syncCachedProfileSaves();
        return true;
      } catch (e) {
        // L'endpoint est toujours indisponible
        final errorMsg = e.toString();
        debugPrint('⚠️ Endpoint /user/profile/saves toujours indisponible: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + '...' : errorMsg}');
        return false;
      }
    }
    return true;
  }
  
  /// Synchronise les sauvegardes en cache avec le backend
  /// Appelé quand l'endpoint devient disponible
  Future<void> _syncCachedProfileSaves() async {
    if (!_endpointAvailable || _profileSavesCache.isEmpty) return;
    
    debugPrint('🔄 Synchronisation des sauvegardes du profil avec le backend...');
    
    // Parcourir le cache et synchroniser chaque sauvegarde
    for (var entry in _profileSavesCache.entries) {
      final saveId = entry.key;
      final saveData = entry.value;
      
      if (saveData['synced'] == false) {
        try {
          await _apiClient.post(
            '/user/profile/saves',
            body: {
              'save_id': saveData['save_id'],
              'game_mode': saveData['game_mode'],
              'metadata': saveData['metadata'] ?? {},
            },
          );
          
          // Marquer comme synchronisé
          saveData['synced'] = true;
          debugPrint('✅ Sauvegarde $saveId synchronisée avec le backend');
        } catch (e) {
          debugPrint('❌ Échec de synchronisation de la sauvegarde $saveId: $e');
        }
      }
    }
    
    // Sauvegarder le cache mis à jour
    await _saveProfileSavesCache();
  }
}
