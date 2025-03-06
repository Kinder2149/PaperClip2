// lib/core/extensions/dart_extensions.dart

/// Extensions pour les types numériques
extension NumExtensions on num {
  /// Formatte un nombre avec un nombre maximum de décimales
  String formatDecimal([int decimals = 2]) {
    return toStringAsFixed(decimals);
  }

  /// Vérifie si le nombre est dans un intervalle
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// Convertit un nombre en pourcentage
  String toPercentage([int decimals = 2]) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }
}

/// Extensions pour les chaînes de caractères
extension StringExtensions on String {
  /// Capitalise la première lettre d'une chaîne
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Limite la longueur d'une chaîne
  String truncate(int maxLength, {String ellipsis = '...'}) {
    return length <= maxLength
        ? this
        : '${substring(0, maxLength)}$ellipsis';
  }

  /// Vérifie si la chaîne est un nombre valide
  bool get isNumeric {
    return double.tryParse(this) != null;
  }
}

/// Extensions pour les listes
extension ListExtensions<T> on List<T> {
  /// Obtient un élément aléatoire dans une liste
  T? randomElement() {
    return isEmpty ? null : this[DateTime.now().millisecond % length];
  }

  /// Divise une liste en sous-listes de taille donnée
  List<List<T>> chunk(int size) {
    List<List<T>> chunks = [];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, min(i + size, length)));
    }
    return chunks;
  }
}

/// Extensions pour les dates
extension DateExtensions on DateTime {
  /// Formate une date en français
  String toFrenchFormat() {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '$day ${months[month - 1]} $year';
  }

  /// Calcule la différence en années
  int yearsBetween(DateTime other) {
    int years = year - other.year;
    if (month < other.month || (month == other.month && day < other.day)) {
      years--;
    }
    return years;
  }
}