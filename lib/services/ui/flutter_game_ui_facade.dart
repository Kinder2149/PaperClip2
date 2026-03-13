import 'package:flutter/material.dart';

import 'package:paperclip2/screens/competitive_result_screen.dart';
import 'package:paperclip2/screens/main_screen.dart';
import 'package:paperclip2/services/navigation_service.dart';
import 'package:paperclip2/services/notification_manager.dart' as snack;
import 'package:paperclip2/services/ui/game_ui_port.dart';

class FlutterGameUiFacade implements GameUiPort {
  final NavigationService _navigation;

  const FlutterGameUiFacade(this._navigation);

  @override
  void showPriceExcessiveWarning({
    required String title,
    required String description,
    required String? detailedDescription,
  }) {
    snack.NotificationManager.instance.showNotification(
      message: '$title\n$description',
      level: snack.NotificationLevel.WARNING,
    );
  }

  @override
  void showUnlockNotification(String message) {
    snack.NotificationManager.instance.showNotification(
      message: message,
      level: snack.NotificationLevel.SUCCESS,
    );
  }

  @override
  void showLeaderboardUnavailable(String message) {
    snack.NotificationManager.instance.showNotification(
      message: message,
      level: snack.NotificationLevel.WARNING,
    );
  }

  @override
  void showCompetitiveResult(CompetitiveResultData data) {
    final context = _navigation.currentContext;
    if (context == null) {
      snack.NotificationManager.instance.showNotification(
        message: 'Navigation indisponible: impossible d\'afficher le résultat',
        level: snack.NotificationLevel.WARNING,
      );
      return;
    }

    _navigation.push(
      MaterialPageRoute(
        builder: (_) => CompetitiveResultScreen(
          score: data.score,
          paperclips: data.paperclips,
          money: data.money,
          playTime: data.playTime,
          level: data.level,
          efficiency: data.efficiency,
          onNewGame: () {
            _navigation.pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
            );
          },
          onShowLeaderboard: () {},
        ),
      ),
    );
  }
}
