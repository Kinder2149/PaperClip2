import 'supabase_cloud_save_adapter.dart';
import 'supabase_friends_repository.dart';
import 'cloud_save_service.dart';
import '../identity/google_identity_service.dart';

CloudSaveService createCloudSaveService({required GoogleIdentityService identity}) {
  final adapter = SupabaseCloudSaveAdapter(getGooglePlayerId: () async => identity.playerId);
  final friends = SupabaseFriendsRepository();
  return CloudSaveService(adapter: adapter, friends: friends);
}
