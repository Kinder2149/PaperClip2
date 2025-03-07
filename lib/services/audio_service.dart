import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences.dart';

class AudioService {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _isMuted = false;
  bool _isMusicEnabled = true;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('isMuted') ?? false;
    _isMusicEnabled = prefs.getBool('isMusicEnabled') ?? true;
  }

  Future<void> playBackgroundMusic(String assetPath) async {
    if (_isMuted || !_isMusicEnabled) return;
    
    try {
      await _backgroundMusicPlayer.setAsset(assetPath);
      await _backgroundMusicPlayer.setLoopMode(LoopMode.one);
      await _backgroundMusicPlayer.play();
    } catch (e) {
      print('Erreur lors de la lecture de la musique: $e');
    }
  }

  Future<void> playEffect(String assetPath) async {
    if (_isMuted) return;
    
    try {
      await _effectPlayer.setAsset(assetPath);
      await _effectPlayer.play();
    } catch (e) {
      print('Erreur lors de la lecture de l\'effet: $e');
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', _isMuted);
    
    if (_isMuted) {
      await _backgroundMusicPlayer.pause();
      await _effectPlayer.pause();
    } else if (_isMusicEnabled) {
      await _backgroundMusicPlayer.play();
    }
  }

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicEnabled', _isMusicEnabled);
    
    if (!_isMusicEnabled) {
      await _backgroundMusicPlayer.pause();
    } else if (!_isMuted) {
      await _backgroundMusicPlayer.play();
    }
  }

  Future<void> dispose() async {
    await _backgroundMusicPlayer.dispose();
    await _effectPlayer.dispose();
  }

  bool get isMuted => _isMuted;
  bool get isMusicEnabled => _isMusicEnabled;
} 