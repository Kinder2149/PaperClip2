// lib/domain/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import '../entities/game_state_entity.dart';
import '../entities/market_entity.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Enregistre un événement de début de partie
  Future<void> logGameStart(GameStateEntity gameState) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {
        'game_mode': gameState.gameMode.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'total_playtime': gameState.totalTimePlayedInSeconds,
      },
    );
  }

  /// Suivi des événements de production
  Future<void> logProduction(int paperclipCount, double metalUsed) async {
    await _analytics.logEvent(
      name: 'paperclip_production',
      parameters: {
        'count': paperclipCount,
        'metal_used': metalUsed,
      },
    );
  }

  /// Suivi des ventes de trombones
  Future<void> logSale(MarketEntity marketState, int quantity, double price) async {
    await _analytics.logEvent(
      name: 'paperclip_sale',
      parameters: {
        'quantity': quantity,
        'price': price,
        'market_reputation': marketState.reputation,
        'market_metal_stock': marketState.marketMetalStock,
      },
    );
  }

  /// Suivi des achats d'améliorations
  Future<void> logUpgradePurchase(String upgradeId, int newLevel) async {
    await _analytics.logEvent(
      name: 'upgrade_purchase',
      parameters: {
        'upgrade_id': upgradeId,
        'new_level': newLevel,
      },
    );
  }

  /// Suivi des achats d'autoclippers
  Future<void> logAutoclipperPurchase(int totalAutoclippers, double cost) async {
    await _analytics.logEvent(
      name: 'autoclipper_purchase',
      parameters: {
        'total_autoclippers': totalAutoclippers,
        'purchase_cost': cost,
      },
    );
  }

  /// Suivi de la progression du niveau
  Future<void> logLevelUp(int newLevel, double experience) async {
    await _analytics.logEvent(
      name: 'level_up',
      parameters: {
        'new_level': newLevel,
        'total_experience': experience,
      },
    );
  }

  /// Suivi des événements critiques
  Future<void> logCriticalEvent(String eventName, Map<String, dynamic> additionalData) async {
    await _analytics.logEvent(
      name: 'critical_event',
      parameters: {
        'event_type': eventName,
        ...additionalData,
      },
    );
  }
}