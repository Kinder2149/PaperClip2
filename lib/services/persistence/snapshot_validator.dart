// lib/services/persistence/snapshot_validator.dart

import 'game_snapshot.dart';

class SnapshotValidationError {
  final String code;
  final String message;
  const SnapshotValidationError(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

class SnapshotValidationResult {
  final bool isValid;
  final List<SnapshotValidationError> errors;
  const SnapshotValidationResult({required this.isValid, required this.errors});
}

/// Valide un GameSnapshot avant toute persistance (locale ou cloud).
/// Règles minimales et strictes (contrat):
/// - racine "metadata" et "core" DOIVENT exister et être Map
/// - racine "stats" DOIT exister et être Map (backend l'attend au minimum)
/// - metadata.schemaVersion (int) doit exister et être >= minSchemaVersion
/// - metadata.enterpriseId (String) non vide (identité technique)
/// - metadata.savedAt (String ISO) facultatif
/// - sections optionnelles: market/production (si présentes: Map)
class SnapshotValidator {
  static const int minSchemaVersion = 1;

  static SnapshotValidationResult validate(GameSnapshot snapshot) {
    final errors = <SnapshotValidationError>[];

    final meta = snapshot.metadata;
    final core = snapshot.core;

    if (meta is! Map<String, dynamic>) {
      errors.add(const SnapshotValidationError('META_TYPE', 'metadata doit être un objet'));
    }
    if (core is! Map<String, dynamic>) {
      errors.add(const SnapshotValidationError('CORE_TYPE', 'core doit être un objet'));
    }

    // Vérifications sur metadata
    if (meta is Map<String, dynamic>) {
      final schemaVersion = meta['schemaVersion'];
      if (schemaVersion is! int) {
        errors.add(const SnapshotValidationError('SCHEMA_VERSION_MISSING', 'metadata.schemaVersion (int) requis'));
      } else if (schemaVersion < minSchemaVersion) {
        errors.add(SnapshotValidationError('SCHEMA_VERSION_UNSUPPORTED', 'schemaVersion=$schemaVersion inférieur au minimum supporté ($minSchemaVersion)'));
      }

      final enterpriseId = meta['enterpriseId'] ?? meta['id'];
      if (enterpriseId is! String || enterpriseId.trim().isEmpty) {
        errors.add(const SnapshotValidationError('ENTERPRISE_ID_MISSING', 'metadata.enterpriseId (ou id) requis, non vide'));
      }

      final version = meta['appVersion'];
      if (version != null && version is! String) {
        errors.add(const SnapshotValidationError('APP_VERSION_TYPE', 'metadata.appVersion doit être une chaîne si présent'));
      }

      // Champs contractuels additionnels (contrat snapshot minimal)
      final createdAt = meta['createdAt'];
      if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
        errors.add(const SnapshotValidationError('CREATED_AT_INVALID', 'metadata.createdAt (String ISO) requis'));
      }

      final lastModified = meta['lastModified'];
      if (lastModified is! String || DateTime.tryParse(lastModified) == null) {
        errors.add(const SnapshotValidationError('LAST_MODIFIED_INVALID', 'metadata.lastModified (String ISO) requis'));
      }

      final contractVersion = meta['version'];
      if (contractVersion is! int) {
        errors.add(const SnapshotValidationError('CONTRACT_VERSION_MISSING', 'metadata.version (int) requis'));
      }
    }

    // Sections optionnelles si présentes
    if (snapshot.market != null && snapshot.market is! Map<String, dynamic>) {
      errors.add(const SnapshotValidationError('MARKET_TYPE', 'market doit être un objet'));
    }
    if (snapshot.production != null && snapshot.production is! Map<String, dynamic>) {
      errors.add(const SnapshotValidationError('PRODUCTION_TYPE', 'production doit être un objet'));
    }
    // Section stats obligatoire (contrat minimal backend)
    if (snapshot.stats == null) {
      errors.add(const SnapshotValidationError('STATS_MISSING', 'stats requis et doit être un objet'));
    } else if (snapshot.stats is! Map<String, dynamic>) {
      errors.add(const SnapshotValidationError('STATS_TYPE', 'stats doit être un objet'));
    }

    return SnapshotValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
