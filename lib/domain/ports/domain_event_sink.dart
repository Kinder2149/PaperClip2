import '../events/domain_event.dart';

abstract interface class DomainEventSink {
  void publish(DomainEvent event);
}
