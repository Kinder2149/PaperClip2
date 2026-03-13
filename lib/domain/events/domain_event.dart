import 'domain_event_type.dart';

class DomainEvent {
  final DomainEventType type;
  final Map<String, Object?> data;

  const DomainEvent({
    required this.type,
    this.data = const <String, Object?>{},
  });
}
