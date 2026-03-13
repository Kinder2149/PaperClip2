// lib/services/storage_constants.dart

/// Constantes partagées pour le système de stockage et sauvegarde
import 'storage_keys.dart';

class StorageConstants {
  /// Préfixe pour les sauvegardes régulières
  static const String SAVE_PREFIX = StorageKeys.legacySavePrefix;
  
  /// Préfixe pour les sauvegardes de secours (backups)
  static const String BACKUP_PREFIX = StorageKeys.legacyBackupPrefix;
  
  /// Version actuelle du format de sauvegarde
  static const String CURRENT_SAVE_FORMAT_VERSION = "2.0";
  
  /// Nombre maximum de backups à conserver par partie
  static const int MAX_BACKUPS = 3;
  
  /// Délimiteur pour les backups automatiques
  static const String BACKUP_DELIMITER = StorageKeys.backupDelimiter;
}
