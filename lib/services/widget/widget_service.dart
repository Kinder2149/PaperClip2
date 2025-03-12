import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/game_config.dart';
import 'package:paperclip2/models/event_system.dart';
import 'dart:math';
import 'widget_interface.dart';

/// Implémentation du service de gestion des widgets
class WidgetService implements WidgetInterface {
  final BuildContext _context;
  
  /// Constructeur
  WidgetService(this._context);
  
  /// Obtient l'état du jeu depuis le contexte
  GameState get _gameState => Provider.of<GameState>(_context, listen: false);
  
  @override
  Widget createMoneyDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final money = gameState.playerManager.money;
        final formattedMoney = formatNumber(money, isInteger: false);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                Icons.attach_money,
                color: textColor ?? Colors.green.shade700,
                size: (fontSize ?? 16) * 1.2,
              ),
            if (showIcon) const SizedBox(width: 4),
            Text(
              formattedMoney,
              style: TextStyle(
                color: textColor ?? Colors.green.shade700,
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget createMetalDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final metal = gameState.playerManager.metal;
        final maxMetal = gameState.playerManager.maxMetalStorage;
        final formattedMetal = formatNumber(metal, isInteger: false);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                Icons.iron,
                color: textColor ?? Colors.grey.shade700,
                size: (fontSize ?? 16) * 1.2,
              ),
            if (showIcon) const SizedBox(width: 4),
            Text(
              compact
                  ? formattedMetal
                  : '$formattedMetal / ${formatNumber(maxMetal, isInteger: false)}',
              style: TextStyle(
                color: textColor ?? Colors.grey.shade700,
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget createPaperclipDisplay({
    double? fontSize,
    Color? textColor,
    bool showIcon = true,
    bool compact = false,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final paperclips = gameState.playerManager.paperclips;
        final formattedPaperclips = formatNumber(paperclips, isInteger: true);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                Icons.push_pin,
                color: textColor ?? Colors.blue.shade700,
                size: (fontSize ?? 16) * 1.2,
              ),
            if (showIcon) const SizedBox(width: 4),
            Text(
              formattedPaperclips,
              style: TextStyle(
                color: textColor ?? Colors.blue.shade700,
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget createLevelDisplay({
    double? fontSize,
    Color? textColor,
    bool showProgress = true,
    bool compact = false,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final level = gameState.levelSystem.level;
        final experience = gameState.levelSystem.experience;
        final nextLevelXP = gameState.levelSystem.getXPForNextLevel();
        final progress = experience / nextLevelXP;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: textColor ?? Colors.amber,
                  size: (fontSize ?? 16) * 1.2,
                ),
                const SizedBox(width: 4),
                Text(
                  'Niveau $level',
                  style: TextStyle(
                    color: textColor ?? Colors.amber,
                    fontSize: fontSize ?? 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (showProgress && !compact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 100,
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            if (showProgress && !compact)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${formatNumber(experience, isInteger: true)} / ${formatNumber(nextLevelXP, isInteger: true)} XP',
                  style: TextStyle(
                    color: textColor?.withOpacity(0.7) ?? Colors.grey.shade600,
                    fontSize: (fontSize ?? 16) * 0.7,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  @override
  Widget createProductionButton({
    double? width,
    double? height,
    VoidCallback? onPressed,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        bool canProduce = gameState.playerManager.metal >= GameConstants.METAL_PER_PAPERCLIP;
        
        return Container(
          height: height ?? 40,
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: canProduce
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed != null
                        ? onPressed()
                        : gameState.producePaperclip();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProduce ? Colors.blue.shade400 : Colors.grey.shade400,
              elevation: canProduce ? 4.0 : 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: canProduce ? Colors.white : Colors.grey.shade300,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.push_pin,
                  color: canProduce ? Colors.white : Colors.grey.shade300,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produire',
                      style: TextStyle(
                        color: canProduce ? Colors.white : Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${GameConstants.METAL_PER_PAPERCLIP} métal',
                      style: TextStyle(
                        color: canProduce
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget createNotificationDisplay({
    NotificationEvent? notification,
    VoidCallback? onDismiss,
    bool autoHide = true,
    Duration? displayDuration,
  }) {
    if (notification == null) return const SizedBox.shrink();
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onDismiss,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(_context).size.width * 0.9,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification).withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                notification.icon ?? Icons.notifications,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.occurrences > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${notification.occurrences} occurrences',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Obtient la couleur de fond pour une notification
  Color _getNotificationColor(NotificationEvent notification) {
    switch (notification.priority) {
      case NotificationPriority.LOW:
        return Colors.grey.shade700;
      case NotificationPriority.MEDIUM:
        return Colors.blue.shade700;
      case NotificationPriority.HIGH:
        return Colors.orange.shade700;
      case NotificationPriority.CRITICAL:
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
  
  @override
  Widget createCompetitiveModeIndicator({
    double? fontSize,
    Color? textColor,
    bool showScore = true,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        if (gameState.gameMode != GameMode.COMPETITIVE) {
          return const SizedBox.shrink();
        }
        
        final score = gameState.calculateCompetitiveScore();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: textColor ?? Colors.white,
                size: (fontSize ?? 16) * 1.2,
              ),
              const SizedBox(width: 4),
              Text(
                showScore ? 'Score: ${formatNumber(score.toDouble(), isInteger: true)}' : 'Mode Compétitif',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget createStatsDisplay({
    List<String>? statsToShow,
    double? fontSize,
    Color? textColor,
    bool compact = false,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final stats = <String, String>{};
        
        // Remplir les statistiques disponibles
        stats['Trombones produits'] = formatNumber(gameState.totalPaperclipsProduced.toDouble(), isInteger: true);
        stats['Argent gagné'] = formatNumber(gameState.playerManager.money, isInteger: false);
        stats['Métal acheté'] = formatNumber(gameState.playerManager.totalMetalBought, isInteger: false);
        stats['Temps de jeu'] = _formatDuration(gameState.totalTimePlayed);
        
        // Filtrer les statistiques à afficher
        final filteredStats = statsToShow != null
            ? Map.fromEntries(stats.entries.where((entry) => statsToShow.contains(entry.key)))
            : stats;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: filteredStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      color: textColor ?? Colors.grey.shade700,
                      fontSize: fontSize ?? 14,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: textColor ?? Colors.grey.shade900,
                      fontSize: fontSize ?? 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  /// Formate une durée en texte lisible
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  @override
  Widget createChartDisplay({
    required String title,
    required List<double> data,
    required List<String> labels,
    double? height,
    Color? lineColor,
    Color? fillColor,
    bool showGrid = true,
  }) {
    // Cette méthode nécessiterait l'utilisation d'une bibliothèque de graphiques comme fl_chart
    // Pour l'instant, nous retournons un placeholder
    return Container(
      height: height ?? 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                'Graphique: ${data.length} points de données',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget createAchievementDisplay({
    required String title,
    required String description,
    required IconData icon,
    required bool unlocked,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked ? Colors.amber.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? Colors.amber.shade700 : Colors.grey.shade500,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.amber.shade800 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (progress != null && progress > 0 && progress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        unlocked ? Colors.amber.shade400 : Colors.blue.shade400,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          if (unlocked)
            Icon(
              Icons.check_circle,
              color: Colors.green.shade500,
              size: 20,
            ),
        ],
      ),
    );
  }
  
  @override
  String formatNumber(double number, {
    bool isInteger = false,
    bool showExactCount = false,
    int maxFractionDigits = 2,
  }) {
    // Si showExactCount est true, on affiche le nombre exact sans formatage
    if (showExactCount) {
      if (isInteger) {
        return number.toStringAsFixed(0);
      }
      return number.toString();
    }
    
    // Liste des suffixes pour les grands nombres
    const suffixes = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
    
    // Fonction helper pour formater avec séparateur de milliers
    String formatWithThousandSeparator(double n) {
      String str = n.toString();
      int dotIndex = str.indexOf('.');
      if (dotIndex == -1) dotIndex = str.length;
      
      String result = '';
      for (int i = 0; i < str.length; i++) {
        if (i < dotIndex && i > 0 && (dotIndex - i) % 3 == 0) {
          result += '.';
        }
        result += str[i];
      }
      return result;
    }
    
    if (number < 1000) {
      // Nombres inférieurs à 1000
      return isInteger
          ? '${number.toStringAsFixed(0)}'
          : '${formatWithThousandSeparator(double.parse(number.toStringAsFixed(maxFractionDigits)))}';
    }
    
    // Pour les grands nombres
    int index = (log(number) / log(1000)).floor();
    index = min(index, suffixes.length - 1);
    double simplified = number / pow(1000, index);
    
    // Formater le nombre simplifié
    String formattedNumber;
    if (simplified >= 100) {
      // Pas de décimales pour les nombres >= 100
      formattedNumber = simplified.toStringAsFixed(0);
    } else if (simplified >= 10) {
      // Une décimale pour les nombres >= 10
      formattedNumber = simplified.toStringAsFixed(1);
    } else {
      // Deux décimales pour les nombres < 10
      formattedNumber = simplified.toStringAsFixed(2);
    }
    
    // Supprimer les zéros inutiles à la fin
    if (formattedNumber.contains('.')) {
      formattedNumber = formattedNumber.replaceAll(RegExp(r'0+$'), '');
      formattedNumber = formattedNumber.replaceAll(RegExp(r'\.$'), '');
    }
    
    return '$formattedNumber${suffixes[index]}';
  }
} 