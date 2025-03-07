import 'package:just_audio/just_audio.dart';

class BackgroundMusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

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
}