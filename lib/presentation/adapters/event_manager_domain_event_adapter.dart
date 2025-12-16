import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/domain/events/domain_event.dart';
import 'package:paperclip2/domain/events/domain_event_type.dart';
import 'package:paperclip2/domain/ports/domain_event_sink.dart';
import 'package:paperclip2/models/event_system.dart';

class EventManagerDomainEventAdapter implements DomainEventSink {
  final EventManager _eventManager;

  EventManagerDomainEventAdapter({EventManager? eventManager})
      : _eventManager = eventManager ?? EventManager.instance;

  @override
  void publish(DomainEvent event) {
    switch (event.type) {
      case DomainEventType.levelUp:
        _eventManager.addEvent(
          EventType.LEVEL_UP,
          event.data['title'] as String? ?? 'Level up',
          description: event.data['description'] as String? ?? '',
          importance: EventImportance.HIGH,
          additionalData: Map<String, dynamic>.from(event.data),
        );
        return;
      case DomainEventType.xpBoostActivated:
        _eventManager.addEvent(
          EventType.XP_BOOST,
          event.data['title'] as String? ?? "Bonus d'XP activé !",
          description: event.data['description'] as String? ?? '',
          importance: EventImportance.MEDIUM,
          additionalData: Map<String, dynamic>.from(event.data),
        );
        return;
      case DomainEventType.milestoneUnlocked:
      case DomainEventType.info:
        _eventManager.addEvent(
          EventType.INFO,
          event.data['title'] as String? ?? 'Info',
          description: event.data['description'] as String? ?? '',
          importance: EventImportance.MEDIUM,
          additionalData: Map<String, dynamic>.from(event.data),
        );
        return;
      case DomainEventType.resourceDepletion:
        _eventManager.addEvent(
          EventType.RESOURCE_DEPLETION,
          event.data['title'] as String? ?? 'Alerte',
          description: event.data['description'] as String? ?? '',
          importance: EventImportance.HIGH,
          additionalData: Map<String, dynamic>.from(event.data),
        );
        return;
    }
  }
}
