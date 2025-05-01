class DateUtils {
  /// Parse une date de manière sécurisée, avec plusieurs formats acceptés
  static DateTime parseDateSafely(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Essayer différents formats

      // Format ISO avec timezone
      final RegExp isoRegex = RegExp(
          r'(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(?:Z|([+-])(\d{2}):(\d{2}))?'
      );

      final isoMatch = isoRegex.firstMatch(dateStr);
      if (isoMatch != null) {
        try {
          return DateTime(
            int.parse(isoMatch.group(1)!),
            int.parse(isoMatch.group(2)!),
            int.parse(isoMatch.group(3)!),
            int.parse(isoMatch.group(4)!),
            int.parse(isoMatch.group(5)!),
            int.parse(isoMatch.group(6)!),
          );
        } catch (_) {}
      }

      // Format simple (YYYY-MM-DD)
      final RegExp simpleRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
      final simpleMatch = simpleRegex.firstMatch(dateStr);
      if (simpleMatch != null) {
        try {
          return DateTime(
            int.parse(simpleMatch.group(1)!),
            int.parse(simpleMatch.group(2)!),
            int.parse(simpleMatch.group(3)!),
          );
        } catch (_) {}
      }

      // En dernier recours, retourner la date actuelle
      print('Format de date non reconnu: $dateStr. Utilisation de la date actuelle.');
      return DateTime.now();
    }
  }

  /// Convertit une date en chaîne ISO standard
  static String formatDateToIso(DateTime date) {
    return date.toIso8601String();
  }
}