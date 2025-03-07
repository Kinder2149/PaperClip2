abstract class IAudioService {
  Future<void> initialize();
  Future<void> playBackgroundMusic(String assetPath);
  Future<void> playEffect(String assetPath);
  Future<void> toggleMute();
  Future<void> toggleMusic();
  Future<void> dispose();
  bool get isMuted;
  bool get isMusicEnabled;
} 