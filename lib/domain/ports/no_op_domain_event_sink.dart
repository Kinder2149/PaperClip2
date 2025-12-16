import '../events/domain_event.dart';
import 'domain_event_sink.dart';

class NoOpDomainEventSink implements DomainEventSink {
  const NoOpDomainEventSink();

  @override
  void publish(DomainEvent event) {}
}
