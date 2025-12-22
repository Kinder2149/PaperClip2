import 'identity_status.dart';
import 'play_games_identity_adapter.dart';

/// Service Identité Google minimal (Étape 1)
/// - Source de vérité: core local (ce service ne touche pas à la save)
/// - Stocke uniquement: `playerId` et `status`
/// - Pas d'orchestration ni de synchronisation ici
class GoogleIdentityService {
  final PlayGamesIdentityAdapter _adapter;

  IdentityStatus _status = IdentityStatus.anonymous;
  String? _playerId;
  String? _displayName;
  String? _avatarUrl;

  GoogleIdentityService({required PlayGamesIdentityAdapter adapter})
      : _adapter = adapter;

  IdentityStatus get status => _status;
  String? get playerId => _playerId;
  String? get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;

  /// Vérifie l'état côté adapter et met à jour le statut local.
  Future<IdentityStatus> refresh() async {
    final signedIn = await _adapter.isSignedIn();
    if (signedIn) {
      _playerId = await _adapter.getPlayerId();
      _displayName = await _adapter.getDisplayName();
      _avatarUrl = await _adapter.getAvatarUrl();
      _status = IdentityStatus.signedIn;
    } else {
      _playerId = null;
      _displayName = null;
      _avatarUrl = null;
      _status = IdentityStatus.anonymous;
    }
    return _status;
  }

  /// Lance un sign-in explicite. Ne déclenche aucune sync ni I/O de save.
  Future<IdentityStatus> signIn() async {
    final ok = await _adapter.signIn();
    if (ok) {
      _playerId = await _adapter.getPlayerId();
      _displayName = await _adapter.getDisplayName();
      _avatarUrl = await _adapter.getAvatarUrl();
      _status = IdentityStatus.signedIn;
    } else {
      _playerId = null;
      _displayName = null;
      _avatarUrl = null;
      _status = IdentityStatus.anonymous;
    }
    return _status;
  }

  /// Sign-out explicite. Ne touche pas au core ni à la save.
  Future<void> signOut() async {
    await _adapter.signOut();
    _playerId = null;
    _displayName = null;
    _avatarUrl = null;
    _status = IdentityStatus.anonymous;
  }
}
