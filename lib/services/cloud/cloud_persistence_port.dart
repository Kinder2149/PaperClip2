import 'models/cloud_world_detail.dart';

// Statut cloud minimal transportant uniquement les informations nécessaires
// à un calcul déterministe côté client.
class CloudStatus {
  final bool exists;
  final DateTime? lastSavedAt;
  final String? gameVersion;
  final String? name;
  CloudStatus({
    required this.exists,
    this.lastSavedAt,
    this.gameVersion,
    this.name,
  });
}

class CloudIndexEntry {
  final String partieId;
  final int? remoteVersion;
  final String? playerId;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final String? name;
  final String? gameVersion;
  CloudIndexEntry({
    required this.partieId,
    this.remoteVersion,
    this.playerId,
    this.lastPushAt,
    this.lastPullAt,
    this.name,
    this.gameVersion,
  });
}

/// MISSION STABILISATION: Port cloud simplifié sans versioning utilisateur.
/// Le backend conserve un historique technique (audit trail) mais le client
/// ne manipule QUE le snapshot courant (state/current).
abstract class CloudPersistencePort {
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  });
  Future<CloudWorldDetail?> pullById({required String partieId});
  Future<CloudStatus> statusById({required String partieId});
  Future<List<CloudIndexEntry>> listParties();
  Future<void> deleteById({required String partieId});
}

class ETagPreconditionException implements Exception {}
