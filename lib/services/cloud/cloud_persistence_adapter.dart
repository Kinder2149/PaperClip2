import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/services/backend/protected_http_client.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/cloud_retry_policy.dart';
import 'package:paperclip2/services/cloud/exceptions/version_conflict_exception.dart';
import 'package:paperclip2/services/cloud/models/cloud_world_detail.dart';
import 'package:paperclip2/services/cloud/models/cloud_worlds_list_response.dart';
import 'package:paperclip2/utils/logger.dart';

/// Adaptateur HTTP (Functions onRequest)
class CloudPersistenceAdapter implements CloudPersistencePort {
  /// P0-2: Regex validation UUID v4
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// où y = [89ab] (bits de variante)
  static final _uuidV4Regex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// P0-2: Valide qu'un partieId est un UUID v4 valide
  /// Lève ArgumentError si invalide
  static void _validatePartieId(String partieId) {
    if (!_uuidV4Regex.hasMatch(partieId)) {
      throw ArgumentError.value(
        partieId,
        'partieId',
        'Doit être un UUID v4 valide (format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx)',
      );
    }
  }
  final Logger _logger = Logger.forComponent('cloud-http');
  final String baseUrl; // ex: https://us-central1-<project>.cloudfunctions.net/api
  final ProtectedHttpClient _client;

  CloudPersistenceAdapter({String? base})
      : baseUrl = (base ?? (dotenv.env['FUNCTIONS_API_BASE'] ?? '')).trim(),
        _client = ProtectedHttpClient(tokenProvider: () => FirebaseAuthService.instance.getIdToken());

  Uri _u(String path) => Uri.parse(baseUrl + path);

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    return cloudRetryPolicy.execute(
      operation: () => _pushByIdInternal(
        partieId: partieId,
        snapshot: snapshot,
        metadata: metadata,
      ),
      operationName: 'pushById($partieId)',
    );
  }

  Future<void> _pushByIdInternal({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validatePartieId(partieId);

    // LOG DÉTAILLÉ : Début push
    _logger.info('[CLOUD-PUSH] START', code: 'cloud_push_start', ctx: {
      'worldId': partieId,
      'baseUrl': baseUrl,
      'hasSnapshot': snapshot.isNotEmpty,
    });

    // CORRECTION AUDIT: Utiliser la méthode centralisée de vérification d'identité
    try {
      final token = await FirebaseAuthService.instance.ensureAuthenticatedForCloud();
      _logger.info('[CLOUD-PUSH] Auth OK', code: 'cloud_push_auth_ok', ctx: {
        'tokenLength': token.length,
      });
    } catch (e, stack) {
      _logger.error('[CLOUD-PUSH] Auth error', code: 'cloud_push_auth_error', ctx: {
        'error': e.toString(),
        'stack': stack.toString(),
      });
      rethrow;
    }

    // Nettoyer les timestamps client
    final meta = Map<String, dynamic>.from(metadata)..remove('savedAt');
    
    // P0-4: Extraire version locale pour détection conflit
    final int? localVersion = metadata['version'] as int?;
    
    // Champs facultatifs côté cloud contract
    final String? name = (metadata['name'] as String?);
    final String? gameVersion = (metadata['game_version'] as String?) ?? (metadata['gameVersion'] as String?);
    final payload = {
      'snapshot': {
        ...snapshot,
        'metadata': {
          ...?snapshot['metadata'] as Map<String, dynamic>?,
          ...meta,
          'worldId': partieId,
        },
      },
      if (name != null) 'name': name,
      if (gameVersion != null) 'game_version': gameVersion,
      // P0-4: Envoyer version attendue pour détection conflit
      if (localVersion != null) 'expected_version': localVersion,
    };
    final url = _u('/worlds/'+partieId);
    try {
      _logger.info('[HTTP] request', code: 'http_put_world', ctx: {
        'method': 'PUT',
        'url': url.toString(),
        'worldId_url': partieId,
        'worldId_payload': (((payload['snapshot'] as Map)['metadata']) as Map)['worldId'],
      });
    } catch (_) {}
    final res = await _client.put(url, body: payload);
    
    // LOG DÉTAILLÉ : Réponse HTTP
    _logger.info('[CLOUD-PUSH] Response', code: 'cloud_push_response', ctx: {
      'worldId': partieId,
      'statusCode': res.statusCode,
      'success': res.statusCode >= 200 && res.statusCode < 300,
    });

    // P0-4: Gérer 409 Conflict (version multi-device)
    if (res.statusCode == 409) {
      _logger.warn('[CLOUD-PUSH] Conflit version détecté (409)', code: 'cloud_conflict_409', ctx: {
        'worldId': partieId,
        'responseBody': res.body?.toString() ?? 'null',
      });
      
      // Extraire versions du body si disponibles
      int? expectedVersion;
      int? actualVersion;
      if (res.body is Map) {
        expectedVersion = res.body['expected_version'] as int?;
        actualVersion = res.body['actual_version'] as int?;
      }
      
      throw VersionConflictException(
        partieId: partieId,
        expectedVersion: expectedVersion,
        actualVersion: actualVersion,
      );
    }
    
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // LOG ERREUR DÉTAILLÉE
      _logger.error('[CLOUD-PUSH] FAILED', code: 'cloud_push_failed', ctx: {
        'worldId': partieId,
        'statusCode': res.statusCode,
        'responseBody': res.body?.toString() ?? 'null',
        'url': url.toString(),
      });
      throw StateError('push_failed_${res.statusCode}');
    }

    // LOG SUCCÈS
    _logger.info('[CLOUD-PUSH] SUCCESS', code: 'cloud_push_ok', ctx: {
      'worldId': partieId,
      'statusCode': res.statusCode,
    });
  }

  @override
  Future<CloudWorldDetail?> pullById({required String partieId}) async {
    return cloudRetryPolicy.execute(
      operation: () => _pullByIdInternal(partieId: partieId),
      operationName: 'pullById($partieId)',
    );
  }

  Future<CloudWorldDetail?> _pullByIdInternal({required String partieId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validatePartieId(partieId);

    _logger.info('[CLOUD-PULL] START', code: 'cloud_pull_start', ctx: {'worldId': partieId});
    
    final res = await _client.get(_u('/worlds/'+partieId));
    
    final body = res.body as Map<String, dynamic>?;
    
    _logger.info('[CLOUD-PULL] Response', code: 'cloud_pull_response', ctx: {
      'worldId': partieId,
      'statusCode': res.statusCode,
      'bodyKeys': body?.keys.join(',') ?? 'null',
      'hasSnapshot': body?.containsKey('snapshot') ?? false,
    });
    
    if (res.statusCode == 404) {
      _logger.info('[CLOUD-PULL] Not found', code: 'cloud_pull_404', ctx: {'worldId': partieId});
      return null;
    }
    if (res.statusCode != 200) {
      _logger.error('[CLOUD-PULL] FAILED', code: 'cloud_pull_failed', ctx: {
        'worldId': partieId,
        'statusCode': res.statusCode,
      });
      throw StateError('pull_failed_${res.statusCode}');
    }
    
    if (body == null) return null;
    
    try {
      final detail = CloudWorldDetail.fromJson(body);
      
      _logger.info('[CLOUD-PULL] Parsed', code: 'cloud_pull_parsed', ctx: {
        'worldId': partieId,
        'hasSnapshot': detail.snapshot.isNotEmpty,
        'name': detail.name,
        'version': detail.version,
        'gameMode': detail.gameMode,
      });
      
      return detail;
    } catch (e) {
      _logger.error('[CLOUD-PULL] JSON parsing failed', code: 'cloud_pull_parse_error', ctx: {
        'worldId': partieId,
        'error': e.toString(),
        'bodyKeys': body.keys.join(','),
      });
      throw StateError('pull_parse_failed: $e');
    }
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validatePartieId(partieId);

    try {
      final res = await _client.get(_u('/worlds/'+partieId));
      if (res.statusCode == 404) return CloudStatus(exists: false);
      if (res.statusCode != 200) return CloudStatus(exists: false);
      
      final body = res.body as Map<String, dynamic>?;
      if (body == null) return CloudStatus(exists: false);
      
      final detail = CloudWorldDetail.fromJson(body);
      return CloudStatus(
        exists: true,
        lastSavedAt: detail.updatedAtDateTime,
        name: detail.name,
        gameVersion: detail.gameVersion,
      );
    } catch (_) {
      return CloudStatus(exists: false);
    }
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return cloudRetryPolicy.execute(
      operation: () => _listPartiesInternal(),
      operationName: 'listParties',
    );
  }

  Future<List<CloudIndexEntry>> _listPartiesInternal() async {
    final res = await _client.get(_u('/worlds'));
    if (res.statusCode != 200) {
      throw StateError('list_failed_${res.statusCode}');
    }
    
    final body = res.body as Map<String, dynamic>?;
    if (body == null) {
      throw StateError('list_failed_empty_body');
    }
    
    try {
      final response = CloudWorldsListResponse.fromJson(body);
      return response.items.map((item) {
        return CloudIndexEntry(
          partieId: item.worldId,
          remoteVersion: null,
          lastPushAt: item.updatedAtDateTime,
          lastPullAt: null,
          name: item.name,
          gameVersion: item.gameVersion,
        );
      }).toList();
    } catch (e) {
      _logger.error('[CLOUD-LIST] JSON parsing failed', code: 'cloud_list_parse_error', ctx: {
        'error': e.toString(),
      });
      throw StateError('list_parse_failed: $e');
    }
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    return cloudRetryPolicy.execute(
      operation: () => _deleteByIdInternal(partieId: partieId),
      operationName: 'deleteById($partieId)',
    );
  }

  Future<void> _deleteByIdInternal({required String partieId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validatePartieId(partieId);

    final res = await _client.delete(_u('/worlds/'+partieId));
    if (res.statusCode != 204 && res.statusCode != 404) {
      throw StateError('delete_failed_${res.statusCode}');
    }
  }

}

/// Adaptateur de repli qui ne fait rien (utilisé pour désactiver le cloud au logout)
class NoopCloudPersistenceAdapter implements CloudPersistencePort {
  @override
  Future<void> deleteById({required String partieId}) async {
    throw UnsupportedError('cloud disabled');
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];

  @override
  Future<CloudWorldDetail?> pullById({required String partieId}) async => null;

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    throw UnsupportedError('cloud disabled');
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(exists: false);
}
