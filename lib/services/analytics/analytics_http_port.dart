import 'package:paperclip2/utils/logger.dart';

import 'analytics_port.dart';

/// Port HTTP d'analytics désactivé (Firebase Callable-only)
class AnalyticsHttpPort implements AnalyticsPort {
  final Logger _logger = Logger.forComponent('analytics');

  Never _unsupported() {
    _logger.warn('AnalyticsHttpPort est désactivé (HTTP interdit).');
    throw UnsupportedError('HTTP backend supprimé. Utiliser une implémentation Callable.');
  }

  @override
  Future<void> recordEvent(String name, Map<String, Object?> properties) async => _unsupported();
}
