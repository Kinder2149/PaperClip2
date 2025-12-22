import 'dart:async';

import '../../../gameplay/events/bus/game_event_bus.dart';
import '../../../gameplay/events/game_event.dart';
import 'leaderboards_service.dart';

/// Adapte les GameEvent normalisés vers LeaderboardsService.
/// - Pas de logique métier ici; attend `eventId` et `payload`.
/// - À brancher côté runtime (bootstrap) et désactivable.
class LeaderboardsEventAdapter {
  final LeaderboardsService _service;
  final GameEventBus? _bus;
  StreamSubscription<GameEvent>? _sub;
  GameEventListener? _listener;
  final void Function(GameEventListener)? _addListener;
  final void Function(GameEventListener)? _removeListener;

  LeaderboardsEventAdapter.withBus({
    required GameEventBus bus,
    required LeaderboardsService service,
  })  : _bus = bus,
        _service = service,
        _addListener = null,
        _removeListener = null;

  LeaderboardsEventAdapter.withListeners({
    required void Function(GameEventListener) addListener,
    required void Function(GameEventListener) removeListener,
    required LeaderboardsService service,
  })  : _bus = null,
        _service = service,
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

  void _onEvent(GameEvent event) {
    final eventId = event.data['eventId'] as String?;
    final payload = (event.data['payload'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    if (eventId == null) return;
    _service.handleEvent(eventId, payload);
  }
}
