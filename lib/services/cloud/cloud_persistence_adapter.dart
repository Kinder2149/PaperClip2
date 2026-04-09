import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/services/backend/protected_http_client.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/cloud_retry_policy.dart';
import 'package:paperclip2/services/cloud/models/cloud_world_detail.dart';
import 'package:paperclip2/utils/logger.dart';

/// Adaptateur HTTP (Functions onRequest)
/// CHANTIER-01 : Utilise API /enterprise pour entreprise unique
class CloudPersistenceAdapter implements CloudPersistencePort {
  /// P0-2: Regex validation UUID v4
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// où y = [89ab] (bits de variante)
  static final _uuidV4Regex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// P0-2: Valide qu'un enterpriseId est un UUID v4 valide
  /// Lève ArgumentError si invalide
  static void _validateEnterpriseId(String enterpriseId) {
    if (!_uuidV4Regex.hasMatch(enterpriseId)) {
      throw ArgumentError.value(
        enterpriseId,
        'enterpriseId',
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
    required String enterpriseId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    return cloudRetryPolicy.execute(
      operation: () => _pushByIdInternal(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: metadata,
      ),
      operationName: 'pushById($enterpriseId)',
    );
  }

  Future<void> _pushByIdInternal({
    required String enterpriseId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validateEnterpriseId(enterpriseId);

    // LOG DÉTAILLÉ : Début push
    _logger.info('[CLOUD-PUSH] START', code: 'cloud_push_start', ctx: {
      'enterpriseId': enterpriseId,
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

    // CHANTIER-01: Récupérer uid Firebase pour API /enterprise
    final uid = FirebaseAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('UID_REQUIRED: Firebase UID manquant pour push cloud');
    }
    
    final payload = {
      'enterpriseId': enterpriseId,
      'snapshot': snapshot,
    };
    final url = _u('/enterprise/'+uid);
    _logger.info('[HTTP] request', code: 'http_put_enterprise', ctx: {
      'method': 'PUT',
      'url': url.toString(),
      'enterpriseId': enterpriseId,
      'uid': uid,
    });
    final res = await _client.put(url, body: payload);
    
    // LOG DÉTAILLÉ : Réponse HTTP
    _logger.info('[CLOUD-PUSH] Response', code: 'cloud_push_response', ctx: {
      'enterpriseId': enterpriseId,
      'statusCode': res.statusCode,
      'success': res.statusCode >= 200 && res.statusCode < 300,
    });

    // CHANTIER-01: API /enterprise ne gère pas les conflits de version (snapshot unique)
    // Les conflits sont résolus par "last write wins"
    
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // LOG ERREUR DÉTAILLÉE
      _logger.error('[CLOUD-PUSH] FAILED', code: 'cloud_push_failed', ctx: {
        'enterpriseId': enterpriseId,
        'statusCode': res.statusCode,
        'responseBody': res.body?.toString() ?? 'null',
        'url': url.toString(),
      });
      throw StateError('push_failed_${res.statusCode}');
    }

    // LOG SUCCÈS
    _logger.info('[CLOUD-PUSH] SUCCESS', code: 'cloud_push_ok', ctx: {
      'enterpriseId': enterpriseId,
      'statusCode': res.statusCode,
    });
  }

  @override
  Future<CloudWorldDetail?> pullById({required String enterpriseId}) async {
    return cloudRetryPolicy.execute(
      operation: () => _pullByIdInternal(enterpriseId: enterpriseId),
      operationName: 'pullById($enterpriseId)',
    );
  }

  Future<CloudWorldDetail?> _pullByIdInternal({required String enterpriseId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validateEnterpriseId(enterpriseId);

    _logger.info('[CLOUD-PULL] START', code: 'cloud_pull_start', ctx: {'enterpriseId': enterpriseId});
    
    // CHANTIER-01: Récupérer uid Firebase pour API /enterprise
    final uid = FirebaseAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('UID_REQUIRED: Firebase UID manquant pour pull cloud');
    }
    
    final res = await _client.get(_u('/enterprise/$uid'));
    
    final body = res.body as Map<String, dynamic>?;
    
    _logger.info('[CLOUD-PULL] Response', code: 'cloud_pull_response', ctx: {
      'enterpriseId': enterpriseId,
      'statusCode': res.statusCode,
      'bodyKeys': body?.keys.join(',') ?? 'null',
      'hasSnapshot': body?.containsKey('snapshot') ?? false,
    });
    
    if (res.statusCode == 404) {
      _logger.info('[CLOUD-PULL] Not found', code: 'cloud_pull_404', ctx: {'enterpriseId': enterpriseId});
      return null;
    }
    if (res.statusCode != 200) {
      _logger.error('[CLOUD-PULL] FAILED', code: 'cloud_pull_failed', ctx: {
        'enterpriseId': enterpriseId,
        'statusCode': res.statusCode,
      });
      throw StateError('pull_failed_${res.statusCode}');
    }
    
    if (body == null) return null;
    
    try {
      final detail = CloudWorldDetail.fromJson(body);
      
      _logger.info('[CLOUD-PULL] Parsed', code: 'cloud_pull_parsed', ctx: {
        'enterpriseId': enterpriseId,
        'hasSnapshot': detail.snapshot.isNotEmpty,
        'name': detail.name,
        'version': detail.version,
        'gameMode': detail.gameMode,
      });
      
      return detail;
    } catch (e) {
      _logger.error('[CLOUD-PULL] JSON parsing failed', code: 'cloud_pull_parse_error', ctx: {
        'enterpriseId': enterpriseId,
        'error': e.toString(),
        'bodyKeys': body.keys.join(','),
      });
      throw StateError('pull_parse_failed: $e');
    }
  }

  @override
  Future<CloudStatus> statusById({required String enterpriseId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validateEnterpriseId(enterpriseId);

    try {
      // CHANTIER-01: Récupérer uid Firebase pour API /enterprise
      final uid = FirebaseAuthService.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        return CloudStatus(exists: false);
      }
      
      final res = await _client.get(_u('/enterprise/$uid'));
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
    // CHANTIER-01: API /enterprise retourne une seule entreprise (pas de liste)
    // Récupérer uid Firebase
    final uid = FirebaseAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return <CloudIndexEntry>[];
    }
    
    final res = await _client.get(_u('/enterprise/$uid'));
    if (res.statusCode == 404) {
      return <CloudIndexEntry>[]; // Pas d'entreprise
    }
    if (res.statusCode != 200) {
      throw StateError('list_failed_${res.statusCode}');
    }
    
    final body = res.body as Map<String, dynamic>?;
    if (body == null) {
      return <CloudIndexEntry>[];
    }
    
    try {
      // Parser la réponse /enterprise (format harmonisé: enterprise_id, updated_at)
      final enterpriseId = body['enterprise_id'] as String?;
      final updatedAt = body['updated_at'] as String?;
      final name = body['name'] as String?;
      final gameVersion = body['game_version'] as String?;
      
      if (enterpriseId == null) {
        return <CloudIndexEntry>[];
      }
      
      return [
        CloudIndexEntry(
          enterpriseId: enterpriseId,
          remoteVersion: 1, // Toujours 1 pour entreprise unique
          lastPushAt: updatedAt != null ? DateTime.tryParse(updatedAt) : null,
          lastPullAt: null,
          name: name,
          gameVersion: gameVersion,
        ),
      ];
    } catch (e) {
      _logger.error('[CLOUD-LIST] JSON parsing failed', code: 'cloud_list_parse_error', ctx: {
        'error': e.toString(),
      });
      throw StateError('list_parse_failed: $e');
    }
  }

  @override
  Future<void> deleteById({required String enterpriseId}) async {
    return cloudRetryPolicy.execute(
      operation: () => _deleteByIdInternal(enterpriseId: enterpriseId),
      operationName: 'deleteById($enterpriseId)',
    );
  }

  Future<void> _deleteByIdInternal({required String enterpriseId}) async {
    // P0-2: Validation UUID v4 avant tout appel HTTP
    _validateEnterpriseId(enterpriseId);

    // CHANTIER-01: Récupérer uid Firebase pour API /enterprise
    final uid = FirebaseAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('UID_REQUIRED: Firebase UID manquant pour delete cloud');
    }

    final res = await _client.delete(_u('/enterprise/$uid'));
    // Backend retourne 204 No Content (REST standard) ou 404 si déjà supprimé
    if (res.statusCode != 204 && res.statusCode != 404) {
      throw StateError('delete_failed_${res.statusCode}');
    }
  }

}

/// Adaptateur de repli qui ne fait rien (utilisé pour désactiver le cloud au logout)
class NoopCloudPersistenceAdapter implements CloudPersistencePort {
  @override
  Future<void> deleteById({required String enterpriseId}) async {
    throw UnsupportedError('cloud disabled');
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];

  @override
  Future<CloudWorldDetail?> pullById({required String enterpriseId}) async => null;

  @override
  Future<void> pushById({
    required String enterpriseId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    throw UnsupportedError('cloud disabled');
  }

  @override
  Future<CloudStatus> statusById({required String enterpriseId}) async => CloudStatus(exists: false);
}
