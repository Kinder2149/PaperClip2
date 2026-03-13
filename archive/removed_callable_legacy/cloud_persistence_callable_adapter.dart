import 'dart:convert';

import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/firebase/firebase_callable_service.dart';
import 'package:paperclip2/utils/logger.dart';

/// Adaptateur Cloud via Firebase Cloud Functions (Callable)
/// - Aucune URL/HTTP côté client
/// - Même interface métier que CloudPersistencePort
class CloudPersistenceCallableAdapter implements CloudPersistencePort {
  final Logger _logger = Logger.forComponent('cloud-callable');

  // Nom des Functions (convention explicite)
  static const String _fPush = 'saves_push';
  static const String _fPullLatest = 'saves_pull_latest';
  static const String _fList = 'saves_list';
  static const String _fDelete = 'saves_delete';
  static const String _fListVersions = 'saves_list_versions';
  static const String _fGetVersion = 'saves_get_version';
  static const String _fRestore = 'saves_restore_version';

  final FirebaseCallableService _svc;
  CloudPersistenceCallableAdapter({FirebaseCallableService? service})
      : _svc = service ?? FirebaseCallableService.instance;

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    // Ne pas transmettre de timestamps client (savedAt) au backend
    final meta = Map<String, dynamic>.from(metadata)..remove('savedAt');
    final payload = <String, dynamic>{
      'partieId': partieId,
      'snapshot': snapshot,
      'metadata': meta,
    };
    _logger.debug('CALL', code: 'push', ctx: {'fn': _fPush, 'partieId': partieId});
    await _svc.call(_fPush, payload: payload);
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    final payload = {'partieId': partieId};
    _logger.debug('CALL', code: 'pull_latest', ctx: {'fn': _fPullLatest, 'partieId': partieId});
    final res = await _svc.call(_fPullLatest, payload: payload);
    if (res == null) return null;
    if (res is Map) {
      return Map<String, dynamic>.from(res as Map);
    }
    if (res is String) {
      return jsonDecode(res) as Map<String, dynamic>;
    }
    throw StateError('Unexpected callable response for pullById');
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    final list = await listParties();
    final exists = list.any((e) => e.partieId == partieId);
    // Pas d’horodatage garanti sans contrat dédié
    return CloudStatus(exists: exists, lastSavedAt: null, gameVersion: null, name: null);
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    _logger.debug('CALL', code: 'list', ctx: {'fn': _fList});
    final res = await _svc.call(_fList);
    final items = <CloudIndexEntry>[];
    if (res is Map && res['items'] is List) {
      for (final e in (res['items'] as List)) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          items.add(CloudIndexEntry(
            partieId: (m['partieId'] ?? m['partie_id'] ?? '').toString(),
            remoteVersion: (m['remoteVersion'] as num?)?.toInt(),
            playerId: m['playerId']?.toString(),
            lastPushAt: (m['lastPushAt'] is String)
                ? DateTime.tryParse(m['lastPushAt'] as String)
                : null,
            lastPullAt: (m['lastPullAt'] is String)
                ? DateTime.tryParse(m['lastPullAt'] as String)
                : null,
            name: m['name']?.toString(),
            gameVersion: m['gameVersion']?.toString(),
          ));
        }
      }
    }
    return items;
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    final payload = {'partieId': partieId};
    _logger.debug('CALL', code: 'delete', ctx: {'fn': _fDelete, 'partieId': partieId});
    await _svc.call(_fDelete, payload: payload);
  }

  // --- Versions APIs ---
  @override
  Future<List<int>> listVersions({required String partieId}) async {
    final payload = {'partieId': partieId};
    _logger.debug('CALL', code: 'versions_list', ctx: {'fn': _fListVersions, 'partieId': partieId});
    final res = await _svc.call(_fListVersions, payload: payload);
    if (res is Map && res['items'] is List) {
      return (res['items'] as List)
          .whereType<Map>()
          .map((e) => (e['version'] as num).toInt())
          .toList();
    }
    if (res is List) {
      return res.map((e) => (e as num).toInt()).toList();
    }
    return <int>[];
  }

  @override
  Future<Map<String, dynamic>?> getVersionSnapshot({required String partieId, required int version}) async {
    final payload = {'partieId': partieId, 'version': version};
    _logger.debug('CALL', code: 'version_get', ctx: {'fn': _fGetVersion, 'partieId': partieId, 'version': version});
    final res = await _svc.call(_fGetVersion, payload: payload);
    if (res == null) return null;
    if (res is Map && res['snapshot'] is Map) {
      return Map<String, dynamic>.from(res['snapshot'] as Map);
    }
    if (res is String) {
      final m = jsonDecode(res);
      if (m is Map && m['snapshot'] is Map) {
        return Map<String, dynamic>.from(m['snapshot'] as Map);
      }
    }
    return null;
  }

  @override
  Future<bool> restoreVersion({required String partieId, required int version}) async {
    final payload = {'partieId': partieId, 'version': version};
    _logger.debug('CALL', code: 'version_restore', ctx: {'fn': _fRestore, 'partieId': partieId, 'version': version});
    final res = await _svc.call(_fRestore, payload: payload);
    if (res is Map && res['ok'] is bool) return res['ok'] as bool;
    if (res is bool) return res;
    return true; // considérer succès si pas d’erreur
  }
}
