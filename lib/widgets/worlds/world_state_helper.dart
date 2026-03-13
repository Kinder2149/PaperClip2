import 'package:paperclip2/services/persistence/save_aggregator.dart';

/// Helper pour calculer l'état canonique des mondes dans l'UI.
/// 
/// Extrait de SavesFacade pour séparer la logique de présentation
/// de la logique métier de persistance.
/// 
/// Responsabilités:
/// - Calcul état canonique (cloud_synced, cloud_pending, cloud_error, local_only)
/// - Libellés UI lisibles
/// - Détection présence cloud
/// - Normalisation statuts cloud
class WorldStateHelper {
  /// État canonique par monde pour l'UI: 'local_only' | 'cloud_pending' | 'cloud_synced' | 'cloud_error'.
  /// 
  /// Simplifié pour refléter la réalité cloud-first sans flags complexes.
  /// 
  /// États possibles:
  /// - 'cloud_synced': Monde synchronisé avec le cloud
  /// - 'cloud_pending': Monde en attente de synchronisation
  /// - 'cloud_error': Erreur de synchronisation
  /// - 'local_only': Monde uniquement local (pas de cloud ou user non connecté)
  static Future<String> canonicalStateFor(SaveEntry entry) async {
    try {
      // Présence cloud connue via agrégateur
      final hasCloudPresence = hasCloudPresenceSync(entry);

      // Interprétation des états synchronisation détaillés si disponibles
      final normalized = mapCloudStatus(entry.cloudSyncState);
      switch (normalized) {
        case 'in_sync':
          return 'cloud_synced';
        case 'ahead_local':
          return 'cloud_pending';
        case 'ahead_remote':
          return 'cloud_error';
        default:
          break;
      }

      // Sans info fine: si aucune présence cloud → local_only, sinon considérer synchronisé
      if (!hasCloudPresence) return 'local_only';
      return 'cloud_synced';
    } catch (_) {
      return 'local_only';
    }
  }

  /// Libellé court lisible pour l'état canonique (UI lecture seule)
  static String canonicalLabel(String state) {
    switch (state) {
      case 'cloud_synced':
        return 'À jour';
      case 'cloud_pending':
        return 'À synchroniser';
      case 'cloud_error':
        return 'Erreur cloud';
      case 'local_only':
      default:
        return 'Local uniquement';
    }
  }

  /// Normalisation des statuts cloud par sauvegarde.
  /// Retourne l'un des statuts unifiés: 'in_sync' | 'ahead_local' | 'ahead_remote'.
  static String mapCloudStatus(String? cloudSyncState) {
    switch ((cloudSyncState ?? '').trim()) {
      case 'unknown':
        // Présence détectée mais direction inconnue → considérer présent et non bloquant
        return 'in_sync';
      case 'in_sync':
        return 'in_sync';
      case 'ahead_local':
        return 'ahead_local';
      case 'ahead_remote':
        return 'ahead_remote';
      default:
        // Par défaut, ne pas créer de faux positifs → présence potentielle non confirmée
        return 'in_sync';
    }
  }

  /// Détection synchrone de la présence cloud à partir d'une entrée agrégée.
  /// Présent si: entrée de source cloud, version distante non nulle, ou état cloud défini (y compris 'unknown').
  static bool hasCloudPresenceSync(SaveEntry entry) {
    if (entry.source == SaveSource.cloud) return true;
    if (entry.remoteVersion != null) return true;
    if (entry.cloudSyncState != null) return true;
    return false;
  }
}
