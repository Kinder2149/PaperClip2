import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_service.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_adapter.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_models.dart';
import 'package:paperclip2/services/google/cloudsave/supabase_friends_repository.dart';

class _NoopAdapter implements CloudSaveAdapter {
  @override
  Future<CloudSaveRecord?> getById(String id) async => null;
  @override
  Future<bool> isReady() async => true;
  @override
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async => const [];
  @override
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async => record;
  @override
  Future<void> label(String id, {required String label}) async {}
}

class _FakeFriendsRepo implements FriendsRepository {
  final List<String> added = [];
  final List<FriendEntry> _store = [];

  @override
  Future<void> addFriend({required String friendExternalId}) async {
    added.add(friendExternalId);
    _store.add(FriendEntry(friendId: friendExternalId, createdAt: DateTime.now()));
  }

  @override
  Future<List<FriendEntry>> listFriends() async => List.unmodifiable(_store);
}

void main() {
  group('Friends via CloudSaveService (pass-through)', () {
    test('addFriend delegates to repository', () async {
      final repo = _FakeFriendsRepo();
      final svc = CloudSaveService(adapter: _NoopAdapter(), friends: repo);
      await svc.addFriend(friendExternalId: 'uuid-123');
      expect(repo.added, contains('uuid-123'));
      final list = await svc.listFriends();
      expect(list.map((e) => e.friendId), contains('uuid-123'));
    });

    test('listFriends returns empty when no repository provided', () async {
      final svc = CloudSaveService(adapter: _NoopAdapter());
      final list = await svc.listFriends();
      expect(list, isEmpty);
    });
  });
}
