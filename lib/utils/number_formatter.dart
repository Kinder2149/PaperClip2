import 'dart:math';

class NumberFormatter {
  static String formatNumber(double number, {bool isInteger = false, bool showExactCount = false, String? suffix}) {
    // Si showExactCount est true, on affiche le nombre exact sans formatage
    if (showExactCount) {
      if (isInteger) {
        return '${number.toStringAsFixed(0)}${suffix ?? ''}';
      }
      return '${number.toString()}${suffix ?? ''}';
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
          ? '${number.toStringAsFixed(0)}${suffix ?? ''}'
          : '${formatWithThousandSeparator(double.parse(number.toStringAsFixed(2)))}${suffix ?? ''}';
    }

    // Pour les grands nombres
    int index = (log(number) / log(1000)).floor();
    index = min(index, suffixes.length - 1);
    double simplified = number / pow(1000, index);

    // Formatage avec plus de précision
    String formatted;
    if (simplified >= 100) {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else if (simplified >= 10) {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    }

    return '$formatted${suffixes[index]}${suffix ?? ''}';
  }
} 