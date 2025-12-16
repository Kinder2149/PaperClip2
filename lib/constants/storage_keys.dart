class StorageKeys {
  static const String legacySavePrefix = 'paperclip_save_';

  static const String legacyBackupPrefix = 'paperclip_backup_';

  static const String saveMetadataPrefix = 'save_metadata_';
  static const String saveDataPrefix = 'save_data_';

  static const String backupDelimiter = '_backup_';

  static const String notificationsPrefix = 'notifications_';
  static const String legacyImportantNotificationsKey = 'important_notifications';

  static String saveMetadataKey(String saveId) => '$saveMetadataPrefix$saveId';
  static String saveDataKey(String saveId) => '$saveDataPrefix$saveId';

  static String notificationsKey(String gameName) => '${notificationsPrefix}${gameName.trim()}';

  static String legacyStablePreMigrationBackupKey(String legacySaveKey) =>
      '${legacySaveKey}_backup_pre_migration';
}
