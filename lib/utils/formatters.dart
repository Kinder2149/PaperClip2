import 'package:intl/intl.dart';

class GameFormatters {
  // Formatage des nombres
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat _compactNumberFormat = NumberFormat.compact(
    locale: 'fr_FR',
    decimalDigits: 1,
  );

  static final NumberFormat _percentFormat = NumberFormat.percentPattern('fr_FR');

  // Formatage des durées
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static String formatCompactDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Formatage des nombres
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCompactNumber(double number) {
    return _compactNumberFormat.format(number);
  }

  static String formatPercent(double value) {
    return _percentFormat.format(value);
  }

  // Formatage des ressources
  static String formatPaperclips(double count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toStringAsFixed(0);
  }

  static String formatMetal(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(1);
  }

  // Formatage des scores et classements
  static String formatScore(int score) {
    return _compactNumberFormat.format(score);
  }

  static String formatRank(int rank) {
    return '#$rank';
  }

  // Formatage des dates
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inSeconds}s';
    }
  }

  // Formatage des noms et textes
  static String formatPlayerName(String name) {
    if (name.length > 20) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  static String formatAchievementName(String name) {
    return name.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Formatage des statistiques
  static String formatProductionRate(double rate) {
    return '${rate.toStringAsFixed(1)}/s';
  }

  static String formatEfficiency(double efficiency) {
    return '${(efficiency * 100).toStringAsFixed(1)}%';
  }

  static String formatQuality(double quality) {
    return '${(quality * 100).toStringAsFixed(1)}%';
  }
} 