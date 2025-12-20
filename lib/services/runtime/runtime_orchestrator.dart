abstract class RuntimeOrchestrator {
  void start();
  void stop();
  void pause();
  void resume();
  Future<void> recoverOffline();
}
