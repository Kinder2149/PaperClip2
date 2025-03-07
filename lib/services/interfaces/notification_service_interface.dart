import 'package:flutter/material.dart';
import '../../models/types/game_types.dart';

abstract class INotificationService {
  void showNotification(NotificationEvent event);
  void showAchievement(String title, String description);
  void showLevelUp(int newLevel, List<UnlockableFeature> newFeatures);
  void showCrisisAlert(String message);
  void showMarketEvent(MarketEvent event);
  void clearNotifications();
  void setContext(BuildContext context);
} 