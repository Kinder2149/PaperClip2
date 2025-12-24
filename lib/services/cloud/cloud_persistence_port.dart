// lib/services/cloud/cloud_persistence_port.dart

import 'dart:async';

/// Représente l'état de synchronisation cloud d'une partie.
class CloudStatus {
  final String partieId;
  final String syncState; // in_sync | ahead_local | ahead_remote | diverged | unknown
  final int? remoteVersion;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final String? playerId;

  const CloudStatus({
    required this.partieId,
    required this.syncState,
    this.remoteVersion,
    this.lastPushAt,
    this.lastPullAt,
    this.playerId,
  });
}

/// Entrée d'index cloud pour une partie disponible côté distant.
class CloudIndexEntry {
  final String partieId;
  final String? name;
  final String? gameVersion;
  final int? remoteVersion;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final String? playerId;

  const CloudIndexEntry({
    required this.partieId,
    this.name,
    this.gameVersion,
    this.remoteVersion,
    this.lastPushAt,
    this.lastPullAt,
    this.playerId,
  });
}

/// Port d'abstraction pour la persistance cloud par partie.
/// L'implémentation concrète (ex: GPG Snapshots, HTTP backend) sera injectée.
abstract class CloudPersistencePort {
  /// Met à jour le slot cloud de la partie avec l'instantané fourni.
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  });

  /// Récupère le snapshot stocké pour la partie. Retourne null si absent.
  Future<Map<String, dynamic>?> pullById({
    required String partieId,
  });

  /// Retourne l'état de synchronisation cloud pour la partie.
  Future<CloudStatus> statusById({
    required String partieId,
  });

  /// Liste les parties présentes côté cloud pour l'utilisateur courant (si applicable)
  Future<List<CloudIndexEntry>> listParties();

  /// Supprime l'entrée cloud pour une partie.
  Future<void> deleteById({
    required String partieId,
  });
}
