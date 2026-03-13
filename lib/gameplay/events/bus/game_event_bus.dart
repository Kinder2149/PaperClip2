import 'dart:async';
import '../game_event.dart';

typedef GameEventListener = void Function(GameEvent event);

class GameEventBus {
  final List<GameEventListener> _listeners = [];
  // Flux broadcast pour abonnements réactifs (UI/Audio/adapters)
  final StreamController<GameEvent> _controller =
      StreamController<GameEvent>.broadcast();

  /// Stream public permettant de s'abonner à tous les événements
  Stream<GameEvent> get stream => _controller.stream;

  void addListener(GameEventListener listener) {
    _listeners.add(listener);
  }

  void removeListener(GameEventListener listener) {
    _listeners.remove(listener);
  }

  void emit(GameEvent event) {
    final current = List<GameEventListener>.from(_listeners);
    for (final listener in current) {
      try {
        listener(event);
      } catch (_) {
        // Isolation des erreurs des listeners pour éviter d'arrêter la diffusion
      }
    }
    // Diffusion sur le stream (non bloquant)
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

   /// Alias semantic de emit
   void publish(GameEvent event) => emit(event);

   /// Souscription avec filtre optionnel
   Stream<GameEvent> subscribe({
     bool Function(GameEvent event)? where,
   }) {
     if (where == null) return stream;
     return stream.where(where);
   }

   /// Libération des ressources (à appeler au dispose du runtime)
   void close() {
     _controller.close();
     _listeners.clear();
   }
}
