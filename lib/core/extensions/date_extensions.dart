// lib/core/extensions/date_extensions.dart

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

extension DateTimeExtensions on DateTime {
  /// Convertit une date en format lisible français
  String toFrenchFormat({bool withTime = false}) {
    initializeDateFormatting('fr_FR');
    final formatter = withTime
        ? DateFormat('dd MMMM yyyy HH:mm', 'fr_FR')
        : DateFormat('dd MMMM yyyy', 'fr_FR');
    return formatter.format(this);
  }

  /// Calcule l'âge à partir d'une date de naissance
  int get age {
    DateTime today = DateTime.now();
    int age = today.year - year;
    if (today.month < month || (today.month == month && today.day < day)) {
      age--;
    }
    return age;
  }

  /// Vérifie si la date est un jour férié
  bool get isHoliday {
    // Liste simplifiée des jours fériés français
    final holidays = [
      DateTime(year, 1, 1),    // Jour de l'An
      DateTime(year, 5, 1),    // Fête du Travail
      DateTime(year, 5, 8),    // Victoire 1945
      DateTime(year, 7, 14),   // Fête Nationale
      DateTime(year, 11, 11),  // Armistice
      DateTime(year, 12, 25),  // Noël
    ];

    return holidays.any((holiday) =>
    holiday.month == month && holiday.day == day);
  }

  /// Retourne le jour de la semaine en français
  String get dayNameInFrench {
    final days = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    return days[weekday - 1];
  }

  /// Calcule la différence entre deux dates
  String timeSince(DateTime other) {
    final difference = difference(other);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Vérifie si la date est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return now.year == year &&
        now.month == month &&
        now.day == day;
  }

  /// Vérifie si la date est dans le futur
  bool get isFuture => isAfter(DateTime.now());

  /// Vérifie si la date est dans le passé
  bool get isPast => isBefore(DateTime.now());

  /// Formate la date relative (il y a X temps)
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 45) return 'À l\'instant';
    if (difference.inMinutes < 2) return 'Il y a 1 minute';
    if (difference.inMinutes < 45) return 'Il y a ${difference.inMinutes} minutes';
    if (difference.inHours < 2) return 'Il y a 1 heure';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} heures';
    if (difference.inDays < 2) return 'Hier';
    if (difference.inDays < 30) return 'Il y a ${difference.inDays} jours';
    if (difference.inDays < 365) return 'Il y a ${(difference.inDays / 30).floor()} mois';
    return 'Il y a ${(difference.inDays / 365).floor()} ans';
  }
}