abstract class IAnalyticsService {
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters});
  Future<void> logScreenView(String screenName);
  Future<void> logUserAction(String action, {Map<String, dynamic>? parameters});
  Future<void> logError(String error, {Map<String, dynamic>? parameters});
  Future<void> setUserProperty(String name, String value);
  Future<void> startSession();
  Future<void> endSession();
  Future<void> flush();
} 