import 'dart:async';

import '../../gameplay/events/bus/game_event_bus.dart';
import '../../gameplay/events/game_event.dart';
import 'game_ui_port.dart';

/// Adapte les GameEvent en actions UI via GameUiPort.
/// Hors domaine: à instancier/relier au bootstrap/runtime.
class GameUiEventAdapter {
  final GameUiPort _ui;
  final GameEventBus? _bus;
  StreamSubscription<GameEvent>? _sub; // utilisé si bus/stream
  GameEventListener? _listener; // utilisé si add/remove listener
  final void Function(GameEventListener)? _addListener;
  final void Function(GameEventListener)? _removeListener;

  GameUiEventAdapter.withBus({
    required GameEventBus bus,
    required GameUiPort ui,
  })  : _bus = bus,
        _ui = ui,
        _addListener = null,
        _removeListener = null;

  GameUiEventAdapter.withListeners({
    required void Function(GameEventListener) addListener,
    required void Function(GameEventListener) removeListener,
    required GameUiPort ui,
  })  : _bus = null,
        _ui = ui,
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
    if (event.type != GameEventType.importantEventOccurred) return;
    final reason = event.data['reason'] as String?;
    if (reason == null) return;

    switch (reason) {
      case 'ui_show_competitive_result':
        final score = event.data['score'] as int?;
        final paperclips = event.data['paperclips'] as int?;
        final money = (event.data['money'] as num?)?.toDouble();
        final level = event.data['level'] as int?;
        final playTimeSeconds = event.data['playTimeSeconds'] as int?;
        final efficiency = (event.data['efficiency'] as num?)?.toDouble();
        if (score != null && paperclips != null && money != null && level != null && playTimeSeconds != null && efficiency != null) {
          _ui.showCompetitiveResult(
            CompetitiveResultData(
              score: score,
              paperclips: paperclips,
              money: money,
              playTime: Duration(seconds: playTimeSeconds),
              level: level,
              efficiency: efficiency,
            ),
          );
        }
        break;
      case 'ui_price_excessive_warning':
        _ui.showPriceExcessiveWarning(
          title: event.data['title'] as String? ?? 'Attention',
          description: event.data['description'] as String? ?? '',
          detailedDescription: event.data['detailedDescription'] as String?,
        );
        break;
      case 'ui_unlock_notification':
        final message = event.data['message'] as String? ?? '';
        _ui.showUnlockNotification(message);
        break;
      case 'ui_show_production_leaderboard':
      case 'ui_show_banker_leaderboard':
      case 'ui_show_leaderboard':
      case 'ui_show_achievements':
        // Version offline: avertir indisponibilité. Peut être remplacé par navigation plus tard.
        _ui.showLeaderboardUnavailable('Fonctionnalité indisponible en mode hors-ligne.');
        break;
      default:
        break;
    }
  }
}
