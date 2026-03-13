/// CORRECTION AUDIT APPROFONDI #5: Classe pour le résultat de synchronisation cloud
/// 
/// Permet de retourner un statut explicite avec détails au lieu de void pour que l'appelant
/// puisse gérer les échecs et afficher un feedback utilisateur approprié.
class SyncResult {
  final SyncStatus status;
  final List<String> failedWorldIds;
  final String? errorDetails;
  final int syncedCount;
  final int totalCount;
  
  const SyncResult({
    required this.status,
    this.failedWorldIds = const [],
    this.errorDetails,
    this.syncedCount = 0,
    this.totalCount = 0,
  });
  
  // Factory constructors pour les cas courants
  static const SyncResult success = SyncResult(status: SyncStatus.success);
  static const SyncResult noCloudPort = SyncResult(status: SyncStatus.noCloudPort);
  static const SyncResult noUid = SyncResult(status: SyncStatus.noUid);
  static const SyncResult networkError = SyncResult(status: SyncStatus.networkError);
  
  static SyncResult partialSuccess({
    required List<String> failedWorldIds,
    required int syncedCount,
    required int totalCount,
    String? errorDetails,
  }) {
    return SyncResult(
      status: SyncStatus.partialSuccess,
      failedWorldIds: failedWorldIds,
      syncedCount: syncedCount,
      totalCount: totalCount,
      errorDetails: errorDetails,
    );
  }
  
  static SyncResult authenticationError({String? errorDetails}) {
    return SyncResult(
      status: SyncStatus.authenticationError,
      errorDetails: errorDetails,
    );
  }
  
  /// Retourne true si le résultat indique un succès (complet ou partiel)
  bool get isSuccess => status == SyncStatus.success || status == SyncStatus.partialSuccess;
  
  /// Retourne true si le résultat nécessite une action utilisateur
  bool get requiresUserAction {
    switch (status) {
      case SyncStatus.noUid:
      case SyncStatus.authenticationError:
        return true;
      default:
        return false;
    }
  }
  
  /// Message utilisateur lisible avec détails si disponibles
  String get userMessage {
    final baseMessage = status.userMessage;
    
    // Ajouter détails si succès partiel
    if (status == SyncStatus.partialSuccess && failedWorldIds.isNotEmpty) {
      return '$baseMessage ($syncedCount/$totalCount réussis)';
    }
    
    // Ajouter détails d'erreur si disponibles
    if (errorDetails != null && errorDetails!.isNotEmpty) {
      return '$baseMessage: $errorDetails';
    }
    
    return baseMessage;
  }
  
  /// Nom du statut pour logging
  String get name => status.name;
  
  // Opérateur d'égalité pour comparaisons simples (ex: result == SyncResult.success)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is SyncResult) {
      return status == other.status;
    }
    if (other is SyncStatus) {
      return status == other;
    }
    return false;
  }
  
  @override
  int get hashCode => status.hashCode;
}

/// Enum pour le statut de synchronisation
enum SyncStatus {
  /// Synchronisation réussie - Tous les mondes cloud ont été matérialisés
  success,
  
  /// CloudPort non configuré - Impossible de synchroniser sans port cloud actif
  noCloudPort,
  
  /// UID Firebase manquant - Impossible de synchroniser sans authentification
  noUid,
  
  /// Erreur réseau - Échec de communication avec le backend
  networkError,
  
  /// Succès partiel - Certains mondes ont été synchronisés, d'autres ont échoué
  partialSuccess,
  
  /// Erreur d'authentification - Token Firebase invalide ou expiré
  authenticationError,
}

/// Extension pour obtenir un message utilisateur lisible depuis SyncStatus
extension SyncStatusMessage on SyncStatus {
  String get userMessage {
    switch (this) {
      case SyncStatus.success:
        return '✅ Synchronisation réussie';
      case SyncStatus.noCloudPort:
        return '⚠️ Cloud non configuré';
      case SyncStatus.noUid:
        return '⚠️ Authentification Firebase requise';
      case SyncStatus.networkError:
        return '❌ Erreur réseau - Vérifiez votre connexion';
      case SyncStatus.partialSuccess:
        return '⚠️ Synchronisation partielle';
      case SyncStatus.authenticationError:
        return '⚠️ Veuillez vous reconnecter';
    }
  }
}
