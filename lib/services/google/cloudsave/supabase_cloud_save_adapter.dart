import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'cloud_save_adapter.dart';
import 'cloud_save_models.dart';
import '../sync/sync_opt_in.dart';
import '../../supabase/supabase_auth_linker.dart';
import '../../identity/identity_manager.dart';

/// Adapter Supabase pour la sauvegarde cloud (append-only, RLS activé).
/// Identité invisible: ouvre une session Supabase (anonyme par défaut) sans exposer Supabase à l'UI.
class SupabaseCloudSaveAdapter implements CloudSaveAdapter {
  static const String _tableCloudSaves = 'cloud_saves';

  final FutureOr<String?> Function()? _getGooglePlayerId; // optionnel, pour enrichir owner

  SupabaseClient get _client => Supabase.instance.client;

  SupabaseCloudSaveAdapter({FutureOr<String?> Function()? getGooglePlayerId})
      : _getGooglePlayerId = getGooglePlayerId;

  Future<void> _ensureInitialized() async {
    if (!Supabase.instance.isInitialized) {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || anonKey == null) {
        throw StateError('Supabase non configuré: variables .env SUPABASE_URL / SUPABASE_ANON_KEY manquantes');
      }
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
    final syncEnabled = await SyncOptIn.instance.get();
    if (_client.auth.currentSession == null) {
      if (syncEnabled) {
        await SupabaseAuthLinker.ensureGoogleSession(force: true);
      } else {
        await _client.auth.signInAnonymously();
      }
    } else {
      if (syncEnabled) {
        await SupabaseAuthLinker.ensureGoogleSession();
      }
    }

    // Synchroniser les métadonnées d'identité (providers liés) si disponible.
    if (syncEnabled && _getGooglePlayerId != null) {
      try {
        final pid = await _getGooglePlayerId!();
        if (pid != null && pid.isNotEmpty) {
          await IdentityManager().syncLinkedProviders(googlePlayerId: pid);
        }
      } catch (_) {
        // best-effort: ne bloque pas la suite
      }
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      await _ensureInitialized();
      // Vérifier qu'une session existe et que la base est accessible
      return _client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async {
    await _ensureInitialized();

    // Optionnellement, synchroniser owner.playerId si absent
    CloudSaveRecord toUpload = record;
    if ((record.owner.playerId).isEmpty && _getGooglePlayerId != null) {
      final pid = await _getGooglePlayerId!();
      if (pid != null && pid.isNotEmpty) {
        toUpload = CloudSaveRecord(
          id: record.id,
          owner: CloudSaveOwner(provider: 'google', playerId: pid),
          payload: record.payload,
          meta: record.meta,
        );
      }
    }

    final syncEnabled = await SyncOptIn.instance.get();
    if (syncEnabled) {
      if (_client.auth.currentUser == null) {
        throw StateError('Synchronisation activée mais aucune session Supabase disponible');
      }
      if (toUpload.owner.playerId.isEmpty) {
        throw StateError('Synchronisation activée: identifiant Google requis pour le propriétaire');
      }
    }

    final row = {
      'user_id': _client.auth.currentUser!.id,
      'schema_version': toUpload.payload.version,
      'payload': toUpload.toJson(),
      'device_id': toUpload.meta.device.model,
      // created_at auto par défaut
    };

    final inserted = await _client.from(_tableCloudSaves).insert(row).select().single();

    final id = (inserted['id'] as String?) ?? inserted['id']?.toString();
    // Reconstruire un record avec id (les autres champs coté payload restent inchangés)
    return CloudSaveRecord(
      id: id,
      owner: toUpload.owner,
      payload: toUpload.payload,
      meta: toUpload.meta,
    );
  }

  @override
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async {
    await _ensureInitialized();
    // RLS: on ne lit que les lignes de l'utilisateur courant, inutile de filtrer user_id coté client.
    final rows = await _client
        .from(_tableCloudSaves)
        .select()
        .order('created_at', ascending: false);

    final List<CloudSaveRecord> records = [];
    for (final r in rows as List) {
      try {
        final payload = (r['payload'] as Map).cast<String, dynamic>();
        final rec = CloudSaveRecord.fromJson(payload);
        // Filtrage optionnel:
        // - si playerId est fourni (non vide), on ne garde que les révisions correspondantes.
        // - si playerId est vide, on retourne toutes les révisions visibles (RLS par user_id suffit).
        if (playerId.isEmpty || rec.owner.playerId == playerId) {
          // Injecter l'id DB si pas présent
          records.add(CloudSaveRecord(
            id: (r['id'] as String?) ?? r['id']?.toString(),
            owner: rec.owner,
            payload: rec.payload,
            meta: rec.meta,
          ));
        }
      } catch (_) {
        // ignorer les lignes corrompues
      }
    }
    return records;
  }

  @override
  Future<CloudSaveRecord?> getById(String id) async {
    await _ensureInitialized();
    final row = await _client
        .from(_tableCloudSaves)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    try {
      final payload = (row['payload'] as Map).cast<String, dynamic>();
      final rec = CloudSaveRecord.fromJson(payload);
      return CloudSaveRecord(
        id: (row['id'] as String?) ?? row['id']?.toString(),
        owner: rec.owner,
        payload: rec.payload,
        meta: rec.meta,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> label(String id, {required String label}) async {
    // Append-only strict: pas d'UPDATE sur la table principale.
    // Implémentation no-op pour respecter l'interface sans violer la règle.
    return;
  }
}
