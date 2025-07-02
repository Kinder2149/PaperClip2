// lib/services/storage_constants.dart

/// Constantes partagées pour le système de stockage et sauvegarde
class StorageConstants {
  /// Préfixe pour les sauvegardes régulières
  static const String SAVE_PREFIX = 'paperclip_save_';
  
  /// Préfixe pour les sauvegardes de secours (backups)
  static const String BACKUP_PREFIX = 'paperclip_backup_';
  
  /// Version actuelle du format de sauvegarde
  static const String CURRENT_SAVE_FORMAT_VERSION = "2.0";
  
  /// Nombre maximum de backups à conserver par partie
  static const int MAX_BACKUPS = 3;
  
  /// Délimiteur pour les backups automatiques
  static const String BACKUP_DELIMITER = '_backup_';
}
