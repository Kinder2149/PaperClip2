import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service de musique de fond avec logs complètement mutés
class BackgroundMusicService {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _initOk = false;
  
  // Clé pour stocker l'état du son par partie dans les préférences
  static const String _gameMusicStatePrefix = 'game_music_state_';

  Future<void> initialize() async {
    try {
      // Créer AudioPlayer avec logs mutés
      _audioPlayer = AudioPlayer(
        // Désactiver tous les logs internes de just_audio
        audioPipeline: AudioPipeline(
          androidAudioEffects: [],
        ),
      );
      
      await _audioPlayer.setAsset('assets/audio/screenmusic.wav');
      await _audioPlayer.setLoopMode(LoopMode.one);
      _initOk = true;
    } catch (e) {
      // Silencieux - pas de log pour les erreurs audio
      _initOk = false;
    }
  }

  Future<void> play() async {
    if (!_isPlaying) {
      if (!_initOk) {
        return;
      }
      try {
        await _audioPlayer.play();
        _isPlaying = true;
      } catch (e) {
        // Silencieux - pas de log
        _isPlaying = false;
      }
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      try {
        await _audioPlayer.pause();
        _isPlaying = false;
      } catch (e) {
        // Silencieux
      }
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      // Silencieux
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    try {
      _audioPlayer.dispose();
    } catch (e) {
      // Silencieux
    }
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