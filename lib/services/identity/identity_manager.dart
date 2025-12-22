import 'package:supabase_flutter/supabase_flutter.dart';

class IdentityManager {
  SupabaseClient? _clientOrNull() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCanonicalUserId() async {
    try {
      final client = _clientOrNull();
      return client?.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserMetadata() async {
    try {
      final client = _clientOrNull();
      if (client == null) return null;
      final data = client.auth.currentUser?.userMetadata;
      return data?.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> syncLinkedProviders({String? googlePlayerId, String? email}) async {
    final client = _clientOrNull();
    if (client == null) return; // no-op when not configured
    if (client.auth.currentUser == null) return;
    final metadata = Map<String, dynamic>.from((await getUserMetadata()) ?? const {});
    final linked = Map<String, dynamic>.from((metadata['linked_provider_ids'] as Map?)?.cast<String, dynamic>() ?? const {});
    if (googlePlayerId != null && googlePlayerId.isNotEmpty) {
      linked['google_play_games'] = googlePlayerId;
    }
    if (email != null && email.isNotEmpty) {
      linked['email'] = email;
    }
    metadata['linked_provider_ids'] = linked;
    await client.auth.updateUser(UserAttributes(data: metadata));
  }

  Future<void> markMigrationDone({DateTime? at}) async {
    final client = _clientOrNull();
    if (client == null) return; // no-op when not configured
    if (client.auth.currentUser == null) return;
    final metadata = Map<String, dynamic>.from((await getUserMetadata()) ?? const {});
    metadata['migration_done_at'] = (at ?? DateTime.now()).toIso8601String();
    await client.auth.updateUser(UserAttributes(data: metadata));
  }

  Future<bool> isMigrationDone() async {
    final metadata = await getUserMetadata();
    return (metadata?['migration_done_at'] as String?) != null;
  }
}
