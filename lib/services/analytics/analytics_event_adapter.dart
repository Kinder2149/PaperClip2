// lib/services/analytics/analytics_event_adapter.dart
import 'dart:async';

import '../../gameplay/events/bus/game_event_bus.dart';
import '../../gameplay/events/game_event.dart';
import 'analytics_port.dart';

/// Adapte les GameEvent vers un AnalyticsPort (HTTP, etc.).
/// Hors domaine: s'instancie au bootstrap et s'abonne au bus d'événements.
class AnalyticsEventAdapter {
  final AnalyticsPort _port;
  final GameEventBus? _bus;
  StreamSubscription<GameEvent>? _sub;
  GameEventListener? _listener;
  final void Function(GameEventListener)? _addListener;
  final void Function(GameEventListener)? _removeListener;

  AnalyticsEventAdapter.withBus({
    required GameEventBus bus,
    required AnalyticsPort port,
  })  : _bus = bus,
        _port = port,
        _addListener = null,
        _removeListener = null;

  AnalyticsEventAdapter.withListeners({
    required void Function(GameEventListener) addListener,
    required void Function(GameEventListener) removeListener,
    required AnalyticsPort port,
  })  : _bus = null,
        _port = port,
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

  Future<void> _onEvent(GameEvent event) async {
    try {
      switch (event.type) {
        case GameEventType.upgradePurchased:
          await _port.recordEvent('upgrade_purchased', event.data);
          break;
        case GameEventType.autoclipperPurchased:
          await _port.recordEvent('autoclipper_purchased', event.data);
          break;
        case GameEventType.metalPurchased:
          await _port.recordEvent('metal_purchased', event.data);
          break;
        case GameEventType.saleProcessed:
          await _port.recordEvent('sale_processed', event.data);
          break;
        default:
          break;
      }
    } catch (_) {
      // Ne pas casser le flux en cas d'erreur d'analytics
    }
  }
}
