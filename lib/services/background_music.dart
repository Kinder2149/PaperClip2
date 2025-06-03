import 'package:just_audio/just_audio.dart';

class BackgroundMusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _audioPlayer.setAsset('assets/audio/screenmusic.wav');
      await _audioPlayer.setLoopMode(LoopMode.one);
      _isInitialized = true;
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
}