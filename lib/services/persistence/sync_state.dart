/// États de synchronisation cloud pour GamePersistenceOrchestrator
/// 
/// Cet enum centralise tous les états possibles de la synchronisation cloud
/// pour éviter les incohérences et faciliter la gestion des états dans l'UI.
enum SyncState {
  /// Prêt - Aucune synchronisation en cours
  ready,
  
  /// Synchronisation en cours (upload vers cloud)
  syncing,
  
  /// Téléchargement en cours (download depuis cloud)
  downloading,
  
  /// Erreur de synchronisation
  error,
  
  /// En attente d'identification (utilisateur non connecté)
  pendingIdentity,
}

/// Extension pour faciliter l'utilisation de SyncState
extension SyncStateExtension on SyncState {
  /// Retourne true si une opération cloud est en cours
  bool get isActive => this == SyncState.syncing || this == SyncState.downloading;
  
  /// Retourne true si l'état est prêt
  bool get isReady => this == SyncState.ready;
  
  /// Retourne true si l'état est en erreur
  bool get hasError => this == SyncState.error;
  
  /// Retourne true si en attente d'identification
  bool get needsIdentity => this == SyncState.pendingIdentity;
  
  /// Retourne un label utilisateur pour l'état
  String get userLabel {
    switch (this) {
      case SyncState.ready:
        return 'À jour';
      case SyncState.syncing:
        return 'Synchronisation…';
      case SyncState.downloading:
        return 'Téléchargement…';
      case SyncState.error:
        return 'Erreur de synchronisation';
      case SyncState.pendingIdentity:
        return 'Connexion requise';
    }
  }
  
  /// Retourne une icône appropriée pour l'état
  String get iconName {
    switch (this) {
      case SyncState.ready:
        return 'cloud_done';
      case SyncState.syncing:
        return 'cloud_upload';
      case SyncState.downloading:
        return 'cloud_download';
      case SyncState.error:
        return 'error_outline';
      case SyncState.pendingIdentity:
        return 'person_off';
    }
  }
}
