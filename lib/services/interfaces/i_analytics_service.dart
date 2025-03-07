abstract class IAnalyticsService {
  Future<void> initialize();
  Future<void> startSession();
  Future<void> endSession();
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> logError(String error, {Map<String, dynamic>? parameters});
  Future<void> setUserProperty(String name, String value);
  Future<void> trackScreen(String screenName);
  Future<void> trackPurchase(String itemId, double price);
} 