// lib/services/save_system/save_game_manager.dart
// Interface pour le gestionnaire de sauvegarde unifié

import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Interface abstraite définissant les opérations de gestion des sauvegardes.
/// 
/// Cette interface fournit un contrat standard pour toutes les opérations
/// liées à la sauvegarde et au chargement des parties, ainsi qu'à la gestion
/// des métadonnées associées.
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
    GameMode gameMode = GameMode.INFINITE,
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
