import 'package:flutter/material.dart';

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
    snack.NotificationManager.instance.showNotification(
      message: 'Mode compétitif retiré : résultat non disponible.',
      level: snack.NotificationLevel.INFO,
    );
    _navigation.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }
}
