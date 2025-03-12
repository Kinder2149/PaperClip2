import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/event_system.dart';

/// Interface pour les services de gestion des widgets
abstract class WidgetInterface {
  /// Crée un widget d'affichage de l'argent
  Widget createMoneyDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  });
  
  /// Crée un widget d'affichage du métal
  Widget createMetalDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  });
  
  /// Crée un widget d'affichage des trombones
  Widget createPaperclipDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  });
  
  /// Crée un widget d'affichage du niveau
  Widget createLevelDisplay({
    double? fontSize,
    Color? textColor,
    bool showProgress = true,
    bool compact = false,
  });
  
  /// Crée un bouton de production
  Widget createProductionButton({
    double? width,
    double? height,
    VoidCallback? onPressed,
  });
  
  /// Crée un widget d'affichage des notifications
  Widget createNotificationDisplay({
    NotificationEvent? notification,
    VoidCallback? onDismiss,
    bool autoHide = true,
    Duration? displayDuration,
  });
  
  /// Crée un widget d'affichage du mode compétitif
  Widget createCompetitiveModeIndicator({
    double? fontSize,
    Color? textColor,
    bool showScore = true,
  });
  
  /// Crée un widget d'affichage des statistiques
  Widget createStatsDisplay({
    List<String>? statsToShow,
    double? fontSize,
    Color? textColor,
    bool compact = false,
  });
  
  /// Crée un widget d'affichage des graphiques
  Widget createChartDisplay({
    required String title,
    required List<double> data,
    required List<String> labels,
    double? height,
    Color? lineColor,
    Color? fillColor,
    bool showGrid = true,
  });
  
  /// Crée un widget d'affichage des succès
  Widget createAchievementDisplay({
    required String title,
    required String description,
    required IconData icon,
    required bool unlocked,
    double? progress,
  });
  
  /// Formate un nombre pour l'affichage
  String formatNumber(double number, {
    bool isInteger = false,
    bool showExactCount = false,
    int maxFractionDigits = 2,
  });
} 