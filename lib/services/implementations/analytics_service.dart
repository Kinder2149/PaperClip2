import 'package:firebase_analytics/firebase_analytics.dart';
import '../interfaces/i_analytics_service.dart';

class AnalyticsService implements IAnalyticsService {
  final FirebaseAnalytics _analytics;
  DateTime? _sessionStartTime;

  AnalyticsService() : _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  @override
  Future<void> startSession() async {
    _sessionStartTime = DateTime.now();
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': _sessionStartTime!.toIso8601String(),
      },
    );
  }

  @override
  Future<void> endSession() async {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      await _analytics.logEvent(
        name: 'session_end',
        parameters: {
          'duration_seconds': duration.inSeconds,
        },
      );
      _sessionStartTime = null;
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> logError(String error, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: 'error',
      parameters: {
        'error_message': error,
        if (parameters != null) ...parameters,
      },
    );
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  @override
  Future<void> trackScreen(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
    );
  }

  @override
  Future<void> trackPurchase(String itemId, double price) async {
    await _analytics.logPurchase(
      currency: 'EUR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: 'Item $itemId',
          price: price,
        ),
      ],
    );
  }
} 