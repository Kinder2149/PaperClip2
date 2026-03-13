/// P0-4: Exception levée lors d'un conflit de version multi-device (409)
/// 
/// Indique que la version locale ne correspond pas à la version cloud actuelle
class VersionConflictException implements Exception {
  final String partieId;
  final int? expectedVersion;
  final int? actualVersion;
  
  VersionConflictException({
    required this.partieId,
    this.expectedVersion,
    this.actualVersion,
  });
  
  @override
  String toString() {
    return 'VersionConflictException: Conflit détecté pour partieId=$partieId '
           '(attendu: v$expectedVersion, actuel: v$actualVersion)';
  }
}
