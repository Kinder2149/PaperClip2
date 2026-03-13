import 'package:paperclip2/services/audio/game_audio_port.dart';
import 'package:paperclip2/services/background_music.dart';

class FlutterGameAudioFacade implements GameAudioPort {
  final BackgroundMusicService _backgroundMusicService;

  FlutterGameAudioFacade(this._backgroundMusicService);

  @override
  Future<void> loadGameMusicState(String gameName) {
    return _backgroundMusicService.loadGameMusicState(gameName);
  }

  @override
  Future<void> setBgmEnabled(bool enabled) async {
    await _backgroundMusicService.setPlayingState(enabled);
  }

  @override
  Future<void> playSfx(String cue) async {
    // Implémentation minimale: pas de système SFX dédié pour l'instant.
    // No-op pour éviter le couplage; pourra être relié à un AudioCache plus tard.
    return;
  }

  @override
  Future<void> setVolume(double volume) async {
    // Pas d'API de volume exposée par BackgroundMusicService actuellement.
    // No-op permissif.
    return;
  }
}
