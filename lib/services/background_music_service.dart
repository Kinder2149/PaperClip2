import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

enum MusicTrack {
  MENU,
  GAME,
  VICTORY,
  DEFEAT,
}

class BackgroundMusicService with ChangeNotifier {
  // Singleton
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  static BackgroundMusicService get instance => _instance;
  
  BackgroundMusicService._internal() {
    if (kDebugMode) {
      print('Service de musique de fond initialisé');
    }
  }
  
  bool _isMusicEnabled = true;
  bool _isSoundEffectsEnabled = true;
  double _musicVolume = 0.7;
  double _soundEffectsVolume = 1.0;
  MusicTrack _currentTrack = MusicTrack.MENU;
  bool _isPlaying = false;
  
  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEffectsEnabled => _isSoundEffectsEnabled;
  double get musicVolume => _musicVolume;
  double get soundEffectsVolume => _soundEffectsVolume;
  MusicTrack get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  
  // Méthodes
  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (enabled) {
      _resumeMusic();
    } else {
      _pauseMusic();
    }
    notifyListeners();
  }
  
  void setSoundEffectsEnabled(bool enabled) {
    _isSoundEffectsEnabled = enabled;
    notifyListeners();
  }
  
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _updateMusicVolume();
    notifyListeners();
  }
  
  void setSoundEffectsVolume(double volume) {
    _soundEffectsVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  Future<void> playMusic(MusicTrack track) async {
    if (track == _currentTrack && _isPlaying) return;
    
    // Arrêter la piste actuelle si elle est en cours
    if (_isPlaying) {
      await _stopMusic();
    }
    
    _currentTrack = track;
    
    // Ne pas démarrer si la musique est désactivée
    if (!_isMusicEnabled) return;
    
    // Jouer la nouvelle piste
    await _playCurrentTrack();
  }
  
  Future<void> playSound(String soundName) async {
    if (!_isSoundEffectsEnabled) return;
    
    try {
      if (kDebugMode) {
        print('Jouer le son: $soundName');
      }
      // Implémentation de la lecture du son
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la lecture du son: $e');
      }
    }
  }
  
  // Méthodes privées pour la gestion de la musique
  Future<void> _playCurrentTrack() async {
    try {
      String trackPath;
      switch (_currentTrack) {
        case MusicTrack.MENU:
          trackPath = 'assets/audio/menu_music.mp3';
          break;
        case MusicTrack.GAME:
          trackPath = 'assets/audio/game_music.mp3';
          break;
        case MusicTrack.VICTORY:
          trackPath = 'assets/audio/victory_music.mp3';
          break;
        case MusicTrack.DEFEAT:
          trackPath = 'assets/audio/defeat_music.mp3';
          break;
      }
      
      if (kDebugMode) {
        print('Démarrage de la piste: $trackPath');
      }
      
      // Simuler le démarrage de la musique (à remplacer par l'implémentation réelle)
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la lecture de la musique: $e');
      }
      _isPlaying = false;
    }
  }
  
  Future<void> _stopMusic() async {
    try {
      if (kDebugMode) {
        print('Arrêt de la musique');
      }
      
      // Simuler l'arrêt de la musique (à remplacer par l'implémentation réelle)
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'arrêt de la musique: $e');
      }
    }
  }
  
  Future<void> _pauseMusic() async {
    if (!_isPlaying) return;
    
    try {
      if (kDebugMode) {
        print('Pause de la musique');
      }
      
      // Simuler la pause de la musique (à remplacer par l'implémentation réelle)
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise en pause de la musique: $e');
      }
    }
  }
  
  Future<void> _resumeMusic() async {
    if (_isPlaying) return;
    
    try {
      if (kDebugMode) {
        print('Reprise de la musique');
      }
      
      // Simuler la reprise de la musique (à remplacer par l'implémentation réelle)
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la reprise de la musique: $e');
      }
    }
  }
  
  void _updateMusicVolume() {
    if (!_isPlaying) return;
    
    try {
      if (kDebugMode) {
        print('Mise à jour du volume de la musique: $_musicVolume');
      }
      
      // Simuler la mise à jour du volume (à remplacer par l'implémentation réelle)
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du volume de la musique: $e');
      }
    }
  }
  
  // Méthode pour sauvegarder les paramètres audio
  Map<String, dynamic> toJson() {
    return {
      'isMusicEnabled': _isMusicEnabled,
      'isSoundEffectsEnabled': _isSoundEffectsEnabled,
      'musicVolume': _musicVolume,
      'soundEffectsVolume': _soundEffectsVolume,
    };
  }
  
  // Méthode pour charger les paramètres audio
  void loadFromJson(Map<String, dynamic> json) {
    try {
      _isMusicEnabled = json['isMusicEnabled'] ?? _isMusicEnabled;
      _isSoundEffectsEnabled = json['isSoundEffectsEnabled'] ?? _isSoundEffectsEnabled;
      _musicVolume = json['musicVolume']?.toDouble() ?? _musicVolume;
      _soundEffectsVolume = json['soundEffectsVolume']?.toDouble() ?? _soundEffectsVolume;
      
      // Mettre à jour l'état de la musique après le chargement
      if (_isMusicEnabled && !_isPlaying) {
        _resumeMusic();
      } else if (!_isMusicEnabled && _isPlaying) {
        _pauseMusic();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des paramètres audio: $e');
      }
    }
  }
}
