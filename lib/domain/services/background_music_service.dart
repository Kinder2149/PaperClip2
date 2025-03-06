// lib/domain/services/background_music_service.dart
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class BackgroundMusicService {
  late AudioPlayer _audioPlayer;
  final _volumeSubject = BehaviorSubject<double>.seeded(0.5);
  final _isPlayingSubject = BehaviorSubject<bool>.seeded(false);

  BackgroundMusicService() {
    _audioPlayer = AudioPlayer();

    // Configuration de l'audio en boucle
    _audioPlayer.setLoopMode(LoopMode.one);
  }

  // Initialisation de la musique
  Future<void> initialize({
    String musicPath = 'assets/audio/screenmusic.wav',
  }) async {
    try {
      await _audioPlayer.setAsset(musicPath);
      _audioPlayer.playerStateStream.listen((state) {
        _isPlayingSubject.add(state.playing);
      });
    } catch (e) {
      print('Erreur d\'initialisation musicale : $e');
    }
  }

  // Lecture de la musique
  Future<void> play() async {
    try {
      await _audioPlayer.play();
      _isPlayingSubject.add(true);
    } catch (e) {
      print('Erreur de lecture musicale : $e');
    }
  }

  // Pause de la musique
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlayingSubject.add(false);
    } catch (e) {
      print('Erreur de pause musicale : $e');
    }
  }

  // Définir le volume
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(volume);
    _volumeSubject.add(volume);
  }

  // Augmenter le volume
  Future<void> increaseVolume() async {
    double currentVolume = _volumeSubject.value;
    await setVolume(currentVolume + 0.1);
  }

  // Diminuer le volume
  Future<void> decreaseVolume() async {
    double currentVolume = _volumeSubject.value;
    await setVolume(currentVolume - 0.1);
  }

  // Getter pour le statut de lecture
  bool get isPlaying => _isPlayingSubject.value;

  // Stream du volume
  Stream<double> get volumeStream => _volumeSubject.stream;

  // Stream du statut de lecture
  Stream<bool> get playingStream => _isPlayingSubject.stream;

  // Libération des ressources
  void dispose() {
    _audioPlayer.dispose();
    _volumeSubject.close();
    _isPlayingSubject.close();
  }
}