import '../game_event.dart';

typedef GameEventListener = void Function(GameEvent event);

class GameEventBus {
  final List<GameEventListener> _listeners = [];

  void addListener(GameEventListener listener) {
    _listeners.add(listener);
  }

  void removeListener(GameEventListener listener) {
    _listeners.remove(listener);
  }

  void emit(GameEvent event) {
    final current = List<GameEventListener>.from(_listeners);
    for (final listener in current) {
      listener(event);
    }
  }
}
