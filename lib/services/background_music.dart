import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundMusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  // Clé pour stocker l'état du son par partie dans les préférences
  static const String _gameMusicStatePrefix = 'game_music_state_';

  Future<void> initialize() async {
    try {
      await _audioPlayer.setAsset('assets/audio/screenmusic.wav');
      await _audioPlayer.setLoopMode(LoopMode.one);
    } catch (e) {
      print('Error initializing background music: $e');
    }
  }

  Future<void> play() async {
    if (!_isPlaying) {
      await _audioPlayer.play();
      _isPlaying = true;
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    _audioPlayer.dispose();
  }
  
  // Méthode pour définir directement l'état de lecture
  Future<void> setPlayingState(bool playing) async {
    if (playing && !_isPlaying) {
      await play();
    } else if (!playing && _isPlaying) {
      await pause();
    }
    // Si l'état actuel correspond déjà à l'état demandé, ne rien faire
  }
  
  // Sauvegarde l'état du son pour une partie spécifique
  Future<void> saveGameMusicState(String gameName, bool isPlaying) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gameMusicStatePrefix + gameName, isPlaying);
  }
  
  // Charge l'état du son pour une partie spécifique
  Future<void> loadGameMusicState(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    // Obtient l'état de la musique pour cette partie, ou true par défaut
    bool shouldPlay = prefs.getBool(_gameMusicStatePrefix + gameName) ?? true;
    await setPlayingState(shouldPlay);
  }
}