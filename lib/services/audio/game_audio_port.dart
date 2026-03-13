abstract class GameAudioPort {
  /// Charge l'état musical (BGM) lié à une partie (lecture/pause mémorisée)
  Future<void> loadGameMusicState(String gameName);

  /// Active/désactive la musique de fond (BGM)
  Future<void> setBgmEnabled(bool enabled);

  /// Joue un effet sonore court identifié par un cue logique (ex: 'unlock', 'warning')
  Future<void> playSfx(String cue);

  /// Ajuste le volume global (0.0 - 1.0). Implémentation permissive.
  Future<void> setVolume(double volume);
}
