// lib/services/api/save_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
  
  // Constructeur interne
  SaveService._internal();
  
  /// Initialisation du service
  Future<void> initialize() async {
    // Aucune initialisation spécifique requise pour le moment
    debugPrint('SaveService initialisé');
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
}
