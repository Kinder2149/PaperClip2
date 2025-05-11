// lib/services/save/storage/storage_engine.dart

import 'package:flutter/foundation.dart';
import '../save_types.dart';

/// Interface abstraite pour les moteurs de stockage
abstract class StorageEngine {
  /// Initialise le moteur de stockage
  Future<void> initialize();

  /// Vérifie si le moteur est prêt à être utilisé
  bool get isInitialized;

  /// Sauvegarde un SaveGame
  Future<void> save(SaveGame saveGame);

  /// Charge un SaveGame à partir de son nom
  Future<SaveGame?> load(String name);

  /// Liste toutes les sauvegardes disponibles
  Future<List<SaveGameInfo>> listSaves();

  /// Supprime une sauvegarde
  Future<void> delete(String name);

  /// Vérifie si une sauvegarde existe
  Future<bool> exists(String name);
}