import 'package:flutter/material.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> showNotification({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  });
  Future<void> showAchievement(String title, String message);
  Future<void> showLevelUp(int level, List<String> newFeatures);
  Future<void> showError(String message);
  Future<void> showWarning(String message);
  Future<void> showSuccess(String message);
  Future<void> showProgress({
    required String title,
    required String message,
    required double progress,
  });
  Future<void> dismissAll();
} 