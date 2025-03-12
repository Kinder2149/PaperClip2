import 'package:flutter/material.dart';
import 'package:paperclip2/models/event_system.dart';
import 'widget_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class WidgetAdapter {
  final WidgetService _widgetService;
  
  /// Constructeur
  WidgetAdapter(this._widgetService);
  
  /// Crée un widget d'affichage de l'argent (compatible avec l'ancien code)
  Widget createMoneyDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return _widgetService.createMoneyDisplay(
      fontSize: fontSize,
      textColor: textColor,
      showIcon: showIcon,
      compact: compact,
    );
  }
  
  /// Crée un widget d'affichage du métal (compatible avec l'ancien code)
  Widget createMetalDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return _widgetService.createMetalDisplay(
      fontSize: fontSize,
      textColor: textColor,
      showIcon: showIcon,
      compact: compact,
    );
  }
  
  /// Crée un widget d'affichage des trombones (compatible avec l'ancien code)
  Widget createPaperclipDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return _widgetService.createPaperclipDisplay(
      fontSize: fontSize,
      textColor: textColor,
      showIcon: showIcon,
      compact: compact,
    );
  }
  
  /// Crée un widget d'affichage du niveau (compatible avec l'ancien code)
  Widget createLevelDisplay({
    double? fontSize,
    Color? textColor,
    bool showProgress = true,
    bool compact = false,
  }) {
    return _widgetService.createLevelDisplay(
      fontSize: fontSize,
      textColor: textColor,
      showProgress: showProgress,
      compact: compact,
    );
  }
  
  /// Crée un bouton de production (compatible avec l'ancien code)
  Widget createProductionButton({
    double? width,
    double? height,
    VoidCallback? onPressed,
  }) {
    return _widgetService.createProductionButton(
      width: width,
      height: height,
      onPressed: onPressed,
    );
  }
  
  /// Crée un widget d'affichage des notifications (compatible avec l'ancien code)
  Widget createNotificationDisplay({
    NotificationEvent? notification,
    VoidCallback? onDismiss,
    bool autoHide = true,
    Duration? displayDuration,
  }) {
    return _widgetService.createNotificationDisplay(
      notification: notification,
      onDismiss: onDismiss,
      autoHide: autoHide,
      displayDuration: displayDuration,
    );
  }
  
  /// Crée un widget d'affichage du mode compétitif (compatible avec l'ancien code)
  Widget createCompetitiveModeIndicator({
    double? fontSize,
    Color? textColor,
    bool showScore = true,
  }) {
    return _widgetService.createCompetitiveModeIndicator(
      fontSize: fontSize,
      textColor: textColor,
      showScore: showScore,
    );
  }
  
  /// Crée un widget d'affichage des statistiques (compatible avec l'ancien code)
  Widget createStatsDisplay({
    List<String>? statsToShow,
    double? fontSize,
    Color? textColor,
    bool compact = false,
  }) {
    return _widgetService.createStatsDisplay(
      statsToShow: statsToShow,
      fontSize: fontSize,
      textColor: textColor,
      compact: compact,
    );
  }
  
  /// Crée un widget d'affichage des graphiques (compatible avec l'ancien code)
  Widget createChartDisplay({
    required String title,
    required List<double> data,
    required List<String> labels,
    double? height,
    Color? lineColor,
    Color? fillColor,
    bool showGrid = true,
  }) {
    return _widgetService.createChartDisplay(
      title: title,
      data: data,
      labels: labels,
      height: height,
      lineColor: lineColor,
      fillColor: fillColor,
      showGrid: showGrid,
    );
  }
  
  /// Crée un widget d'affichage des succès (compatible avec l'ancien code)
  Widget createAchievementDisplay({
    required String title,
    required String description,
    required IconData icon,
    required bool unlocked,
    double? progress,
  }) {
    return _widgetService.createAchievementDisplay(
      title: title,
      description: description,
      icon: icon,
      unlocked: unlocked,
      progress: progress,
    );
  }
  
  /// Formate un nombre pour l'affichage (compatible avec l'ancien code)
  String formatNumber(double number, {
    bool isInteger = false,
    bool showExactCount = false,
    int maxFractionDigits = 2,
  }) {
    return _widgetService.formatNumber(
      number,
      isInteger: isInteger,
      showExactCount: showExactCount,
      maxFractionDigits: maxFractionDigits,
    );
  }
} 