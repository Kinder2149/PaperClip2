import 'package:paperclip2/services/audio/game_audio_port.dart';
import 'package:paperclip2/services/background_music.dart';

class FlutterGameAudioFacade implements GameAudioPort {
  final BackgroundMusicService _backgroundMusicService;

  FlutterGameAudioFacade(this._backgroundMusicService);

  @override
  Future<void> loadGameMusicState(String gameName) {
    return _backgroundMusicService.loadGameMusicState(gameName);
  }
}
