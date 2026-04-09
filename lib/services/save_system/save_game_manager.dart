// lib/services/save_system/save_game_manager.dart
// Interface pour le gestionnaire de sauvegarde unifié

import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Interface définissant les opérations de base pour la gestion des sauvegardes de jeu.
///
/// **Rôle :** Contrat standard pour les implémentations de gestionnaires de sauvegarde.
///
/// **Implémentation actuelle :** `LocalSaveGameManager` (stockage SharedPreferences)
///
/// **Architecture :**
/// - Cette interface permet de découpler les services de haut niveau des détails d'implémentation
/// - Facilite les tests unitaires via des mocks
/// - Permet de changer l'implémentation du stockage sans modifier les services clients
///
/// **Note :** Interface légitime et activement utilisée. Ne pas supprimer.
abstract class SaveGameManager {
  /// Liste toutes les sauvegardes disponibles avec leurs métadonnées
  Future<List<SaveMetadata>> listSaves();
  
  /// Charge une sauvegarde à partir de son identifiant
  Future<SaveGame?> loadSave(String saveId);
  
  /// Sauvegarde une partie en cours
  Future<bool> saveGame(SaveGame save);
  
  /// Supprime une sauvegarde existante
  Future<bool> deleteSave(String saveId);
  
  /// Exporte une sauvegarde vers un fichier externe
  Future<bool> exportSave(String saveId, String path);
  
  /// Importe une sauvegarde depuis un fichier externe
  Future<SaveGame?> importSave(String path);
  
  /// Crée une nouvelle sauvegarde vide avec des paramètres par défaut
  Future<SaveGame> createNewSave({
    String? name,
    Map<String, dynamic>? initialData,
  });
  
  /// Met à jour les métadonnées d'une sauvegarde existante
  Future<bool> updateSaveMetadata(String saveId, SaveMetadata metadata);
  
  /// Récupère les métadonnées d'une sauvegarde
  Future<SaveMetadata?> getSaveMetadata(String saveId);
  
  /// Configure l'auto-sauvegarde pour une sauvegarde spécifique
  Future<void> enableAutoSave({
    required Duration interval,
    required String saveId,
  });
  
  /// Désactive l'auto-sauvegarde
  Future<void> disableAutoSave();
  
  /// Récupère l'identifiant de la sauvegarde active (celle actuellement chargée)
  String? get activeSaveId;
  
  /// Définit la sauvegarde active
  set activeSaveId(String? id);
  
  /// Vérifie si une sauvegarde existe
  Future<bool> saveExists(String saveId);
  
  /// Crée une copie d'une sauvegarde existante
  Future<SaveGame?> duplicateSave(String sourceId, {String? newName});
}
