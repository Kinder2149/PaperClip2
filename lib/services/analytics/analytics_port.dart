// lib/services/analytics/analytics_port.dart

abstract class AnalyticsPort {
  Future<void> recordEvent(String name, Map<String, Object?> properties);
}

class NoOpAnalyticsPort implements AnalyticsPort {
  const NoOpAnalyticsPort();
  @override
  Future<void> recordEvent(String name, Map<String, Object?> properties) async {
    // No-op
  }
}
