import 'dart:async';

import '../../gameplay/events/bus/game_event_bus.dart';
import '../../gameplay/events/game_event.dart';
import 'game_audio_port.dart';

/// Adapte les GameEvent en réactions audio (BGM/SFX) via GameAudioPort.
/// Hors domaine: à instancier/relier au bootstrap/runtime.
class AudioEventAdapter {
  final GameAudioPort _audio;
  final GameEventBus? _bus;
  StreamSubscription<GameEvent>? _sub; // utilisé si bus/stream
  GameEventListener? _listener; // utilisé si add/remove listener
  final void Function(GameEventListener)? _addListener;
  final void Function(GameEventListener)? _removeListener;

  AudioEventAdapter.withBus({
    required GameEventBus bus,
    required GameAudioPort audioPort,
  })  : _bus = bus,
        _audio = audioPort,
        _addListener = null,
        _removeListener = null;

  AudioEventAdapter.withListeners({
    required void Function(GameEventListener) addListener,
    required void Function(GameEventListener) removeListener,
    required GameAudioPort audioPort,
  })  : _bus = null,
        _audio = audioPort,
        _addListener = addListener,
        _removeListener = removeListener;

  void start() {
    if (_bus != null) {
      _sub ??= _bus!.subscribe().listen(_onEvent, onError: (_) {});
      return;
    }
    if (_addListener != null) {
      _listener ??= (e) => _onEvent(e);
      _addListener!.call(_listener!);
    }
  }

  void stop() {
    if (_sub != null) {
      _sub?.cancel();
      _sub = null;
    }
    if (_listener != null && _removeListener != null) {
      _removeListener!.call(_listener!);
      _listener = null;
    }
  }

  void _onEvent(GameEvent event) async {
    if (event.type != GameEventType.importantEventOccurred) return;
    final reason = event.data['reason'] as String?;
    if (reason == null) return;

    try {
      switch (reason) {
        case 'ui_unlock_notification':
          // SFX de succès succinct
          await _audio.playSfx('unlock');
          break;
        case 'ui_price_excessive_warning':
          // SFX d'avertissement léger
          await _audio.playSfx('warning');
          break;
        default:
          break;
      }
    } catch (_) {
      // Ne pas casser le flux en cas d'erreur audio
    }
  }
}
