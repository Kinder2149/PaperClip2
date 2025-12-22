import 'cloud_save_models.dart';

/// Port d'accès au backend de sauvegarde cloud (append-only, opt-in).
/// Aucune logique métier ici; l'adapter transporte simplement les objets.
abstract class CloudSaveAdapter {
  /// Indique si la couche sous-jacente est prête (ex: identité sign_in_sync_enabled, réseau OK).
  Future<bool> isReady();

  /// Crée une nouvelle révision cloud (append-only) et retourne l'enregistrement avec son id.
  Future<CloudSaveRecord> upload(CloudSaveRecord record);

  /// Liste les révisions pour un owner (playerId Google).
  Future<List<CloudSaveRecord>> listByOwner(String playerId);

  /// Récupère une révision par id.
  Future<CloudSaveRecord?> getById(String id);

  /// Marquage optionnel d'une révision (favorite/current). Non destructeur.
  Future<void> label(String id, {required String label});
}
