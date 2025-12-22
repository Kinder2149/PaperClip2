import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../supabase/supabase_auth_linker.dart';

class FriendEntry {
  final String friendId; // UUID Supabase (auth.users.id)
  final DateTime createdAt;
  const FriendEntry({required this.friendId, required this.createdAt});
}

abstract class FriendsRepository {
  Future<void> addFriend({required String friendExternalId});
  Future<List<FriendEntry>> listFriends();
}

class SupabaseFriendsRepository implements FriendsRepository {
  static const String _table = 'friends';

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _ensureInitialized() async {
    if (!Supabase.instance.isInitialized) {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || anonKey == null) {
        throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY manquantes');
      }
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
    if (_client.auth.currentSession == null) {
      await SupabaseAuthLinker.ensureGoogleSession(force: true);
    }
    if (_client.auth.currentSession == null) {
      throw StateError('Session Supabase OAuth Google requise pour Amis');
    }
  }

  @override
  Future<void> addFriend({required String friendExternalId}) async {
    await _ensureInitialized();
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Session Supabase absente');

    final row = {
      'user_id': uid,
      'friend_id': friendExternalId,
    };
    await _client.from(_table).insert(row);
  }

  @override
  Future<List<FriendEntry>> listFriends() async {
    await _ensureInitialized();
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    final List<FriendEntry> out = [];
    for (final r in rows as List) {
      final fid = (r['friend_id'] as String?) ?? r['friend_id']?.toString();
      final created = DateTime.tryParse((r['created_at'] as String?) ?? '') ?? DateTime.now();
      if (fid != null) {
        out.add(FriendEntry(friendId: fid, createdAt: created));
      }
    }
    return out;
  }
}
