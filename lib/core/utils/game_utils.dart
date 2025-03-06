// lib/core/utils/game_utils.dart

import 'dart:math';
import 'package:intl/intl.dart';

class GameUtils {
  /// Formatte un nombre en notation lisible
  static String formatNumber(num number, {int decimals = 2}) {
    if (number < 1000) return number.toStringAsFixed(decimals);

    final suffixes = ['', 'K', 'M', 'B', 'T'];
    int magnitude = (log(number) / log(1000)).floor();

    return '${(number / pow(1000, magnitude)).toStringAsFixed(decimals)}${suffixes[magnitude]}';
  }

  /// Calcule un pourcentage
  static double calculatePercentage(num value, num total) {
    return total == 0 ? 0 : (value / total * 100);
  }

  /// Génère un identifiant unique
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  /// Convertit une durée en chaîne lisible
  static String formatDuration(Duration duration) {
    return duration.toString().split('.').first;
  }

  /// Formate une date en français
  static String formatDateFr(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Interpolation linéaire
  static double lerp(num start, num end, num progress) {
    return start + (end - start) * progress;
  }

  /// Génère un nombre aléatoire dans une plage
  static num randomInRange(num min, num max) {
    return min + Random().nextDouble() * (max - min);
  }

  /// Fonction de lissage (éasing)
  static double easeInOutQuad(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
}

/// Utilitaire pour les probabilités et les jets de dés
class ProbabilityUtils {
  /// Vérifie si un événement se produit avec une probabilité donnée
  static bool probability(double chance) {
    return Random().nextDouble() < chance;
  }

  /// Lance un dé avec un nombre de faces donné
  static int rollDice(int faces) {
    return Random().nextInt(faces) + 1;
  }

  /// Sélectionne un élément aléatoire avec des poids
  static T weightedChoice<T>(List<T> items, List<double> weights) {
    assert(items.length == weights.length);

    final totalWeight = weights.reduce((a, b) => a + b);
    final randomPoint = Random().nextDouble() * totalWeight;

    var currentWeight = 0.0;
    for (int i = 0; i < items.length; i++) {
      currentWeight += weights[i];
      if (randomPoint <= currentWeight) {
        return items[i];
      }
    }

    return items.last;
  }
}