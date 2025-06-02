// lib/services/api/storage_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'api_client.dart';

/// Service de stockage utilisant le backend personnalisé
/// Remplace les fonctionnalités de Firebase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  // Client API
  final ApiClient _apiClient = ApiClient();
  
  // Constructeur interne
  StorageService._internal();
  
  /// Initialisation du service
  Future<void> initialize() async {
    // Aucune initialisation spécifique requise pour le moment
    debugPrint('StorageService initialisé');
  }
  
  /// Upload d'un fichier
  Future<String> uploadFile(
    File file, {
    String? customFileName,
    String folder = 'general',
  }) async {
    try {
      final fileName = customFileName ?? path.basename(file.path);
      
      final data = await _apiClient.uploadFile(
        '/storage/upload?folder=$folder',
        file,
        fileName: fileName,
      );
      
      return data['file_url'];
    } catch (e) {
      debugPrint('Erreur lors de l\'upload du fichier: $e');
      rethrow;
    }
  }
  
  /// Upload d'une image de profil
  Future<Map<String, dynamic>> uploadProfileImage({required File imageFile, required String userId}) async {
    try {
      final data = await _apiClient.uploadFile(
        '/storage/profile-image/$userId',
        imageFile,
      );
      
      return {
        'success': true,
        'url': data['file_url'],
      };
    } catch (e) {
      debugPrint('Erreur lors de l\'upload de l\'image de profil: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  /// Téléchargement d'un fichier
  Future<File> downloadFile(String fileUrl, {String? localFileName}) async {
    try {
      // Extraire le nom du fichier de l'URL
      final fileName = localFileName ?? path.basename(Uri.parse(fileUrl).path);
      
      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final localPath = path.join(tempDir.path, fileName);
      
      // Télécharger le fichier
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Erreur lors du téléchargement du fichier: ${response.statusCode}');
      }
      
      // Sauvegarder le fichier localement
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      
      return file;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement du fichier: $e');
      rethrow;
    }
  }
  
  /// Suppression d'un fichier
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extraire le chemin du fichier de l'URL
      final uri = Uri.parse(fileUrl);
      final filePath = uri.path.replaceFirst('/files/', '');
      
      await _apiClient.delete('/storage/delete?file_path=$filePath');
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du fichier: $e');
      return false;
    }
  }
  
  /// Upload d'une sauvegarde
  Future<String> uploadSave(File saveFile, String saveId) async {
    try {
      final data = await _apiClient.uploadFile(
        '/storage/saves/$saveId',
        saveFile,
      );
      
      return data['file_url'];
    } catch (e) {
      debugPrint('Erreur lors de l\'upload de la sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Téléchargement d'une sauvegarde
  Future<File> downloadSave(String saveId) async {
    try {
      final data = await _apiClient.get('/storage/saves/$saveId');
      
      // Télécharger le fichier
      return await downloadFile(data['file_url'], localFileName: '$saveId.save');
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de la sauvegarde: $e');
      rethrow;
    }
  }
  
  /// Vérification de l'existence d'une sauvegarde
  Future<bool> saveExists(String saveId) async {
    try {
      final data = await _apiClient.get('/storage/saves/$saveId/exists');
      return data['exists'] ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la sauvegarde: $e');
      return false;
    }
  }
  
  /// Obtention de l'URL d'une sauvegarde
  Future<String?> getSaveUrl(String saveId) async {
    try {
      final data = await _apiClient.get('/storage/saves/$saveId');
      return data['file_url'];
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de l\'URL de la sauvegarde: $e');
      return null;
    }
  }
  
  /// Suppression d'une sauvegarde
  Future<bool> deleteSave(String saveId) async {
    try {
      await _apiClient.delete('/storage/saves/$saveId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }
  
  /// Liste des sauvegardes
  Future<List<String>> listSaves() async {
    try {
      final data = await _apiClient.get('/storage/saves');
      return List<String>.from(data['save_ids'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la liste des sauvegardes: $e');
      return [];
    }
  }
}
