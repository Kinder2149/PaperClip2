import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/gameplay/events/bus/game_event_bus.dart';
import 'package:paperclip2/gameplay/events/game_event.dart';
import 'package:paperclip2/services/google/achievements/achievements_event_adapter.dart';
import 'package:paperclip2/services/google/achievements/achievements_service.dart';
import 'package:paperclip2/services/google/achievements/achievements_adapter.dart';
import 'package:paperclip2/services/google/achievements/achievements_mapper.dart';
import 'package:paperclip2/services/google/achievements/achievements_keys.dart';

class _MemAdapter implements AchievementsAdapter {
  bool ready = true;
  final List<String> unlocked = [];
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<void> unlock(String achievementKey) async {
    unlocked.add(achievementKey);
  }
}

void main() {
  test('AchievementsEventAdapter routes normalized events to service', () async {
    final bus = GameEventBus();
    final adapter = _MemAdapter();
    final service = AchievementsService(adapter: adapter, mapper: AchievementsMapper());
    final eventAdapter = AchievementsEventAdapter.withBus(bus: bus, service: service);

    eventAdapter.start();

    bus.emit(GameEvent(
      type: GameEventType.importantEventOccurred,
      data: {
        'eventId': 'production.total_clips',
        'payload': {'total': 10000},
      },
    ));

    // Laisser le temps au stream de livrer l'événement
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.tryFlush();

    expect(adapter.unlocked.contains(AchievementKeys.totalClips10k), isTrue);

    eventAdapter.stop();
    bus.close();
  });
}
