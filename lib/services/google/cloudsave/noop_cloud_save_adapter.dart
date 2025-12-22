import 'cloud_save_adapter.dart';
import 'cloud_save_models.dart';

/// Implémentation No-Op: couche cloud désactivée.
class NoopCloudSaveAdapter implements CloudSaveAdapter {
  @override
  Future<bool> isReady() async => false;

  @override
  Future<CloudSaveRecord?> getById(String id) async => null;

  @override
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async => const [];

  @override
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async => record;

  @override
  Future<void> label(String id, {required String label}) async {}
}
