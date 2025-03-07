import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/utils/formatters.dart';

void main() {
  group('GameFormatters', () {
    group('formatDuration', () {
      test('formate correctement une durée de moins d\'une minute', () {
        expect(
          GameFormatters.formatDuration(const Duration(seconds: 45)),
          '45s',
        );
      });

      test('formate correctement une durée de moins d\'une heure', () {
        expect(
          GameFormatters.formatDuration(const Duration(minutes: 5, seconds: 30)),
          '5m 30s',
        );
      });

      test('formate correctement une durée de plus d\'une heure', () {
        expect(
          GameFormatters.formatDuration(
            const Duration(hours: 2, minutes: 15),
          ),
          '2h 15m',
        );
      });
    });

    group('formatCompactDuration', () {
      test('formate correctement une durée en jours', () {
        expect(
          GameFormatters.formatCompactDuration(const Duration(days: 2)),
          '2j',
        );
      });

      test('formate correctement une durée en heures', () {
        expect(
          GameFormatters.formatCompactDuration(const Duration(hours: 5)),
          '5h',
        );
      });

      test('formate correctement une durée en minutes', () {
        expect(
          GameFormatters.formatCompactDuration(const Duration(minutes: 30)),
          '30m',
        );
      });

      test('formate correctement une durée en secondes', () {
        expect(
          GameFormatters.formatCompactDuration(const Duration(seconds: 45)),
          '45s',
        );
      });
    });

    group('formatCurrency', () {
      test('formate correctement un montant en euros', () {
        expect(GameFormatters.formatCurrency(1234.56), '1 234,56 €');
      });

      test('formate correctement un montant négatif', () {
        expect(GameFormatters.formatCurrency(-1234.56), '-1 234,56 €');
      });

      test('formate correctement un montant nul', () {
        expect(GameFormatters.formatCurrency(0), '0,00 €');
      });
    });

    group('formatCompactNumber', () {
      test('formate correctement un petit nombre', () {
        expect(GameFormatters.formatCompactNumber(123), '123');
      });

      test('formate correctement un nombre en milliers', () {
        expect(GameFormatters.formatCompactNumber(1234), '1,2K');
      });

      test('formate correctement un nombre en millions', () {
        expect(GameFormatters.formatCompactNumber(1234567), '1,2M');
      });
    });

    group('formatPercent', () {
      test('formate correctement un pourcentage', () {
        expect(GameFormatters.formatPercent(0.75), '75 %');
      });

      test('formate correctement un pourcentage nul', () {
        expect(GameFormatters.formatPercent(0), '0 %');
      });

      test('formate correctement un pourcentage de 100%', () {
        expect(GameFormatters.formatPercent(1), '100 %');
      });
    });

    group('formatPaperclips', () {
      test('formate correctement un petit nombre de trombones', () {
        expect(GameFormatters.formatPaperclips(123), '123');
      });

      test('formate correctement un nombre de trombones en milliers', () {
        expect(GameFormatters.formatPaperclips(1234), '1.2K');
      });

      test('formate correctement un nombre de trombones en millions', () {
        expect(GameFormatters.formatPaperclips(1234567), '1.2M');
      });
    });

    group('formatMetal', () {
      test('formate correctement une petite quantité de métal', () {
        expect(GameFormatters.formatMetal(123.45), '123.5');
      });

      test('formate correctement une quantité de métal en milliers', () {
        expect(GameFormatters.formatMetal(1234.56), '1.2K');
      });

      test('formate correctement une quantité de métal en millions', () {
        expect(GameFormatters.formatMetal(1234567.89), '1.2M');
      });
    });

    group('formatScore', () {
      test('formate correctement un petit score', () {
        expect(GameFormatters.formatScore(123), '123');
      });

      test('formate correctement un score en milliers', () {
        expect(GameFormatters.formatScore(1234), '1,2K');
      });

      test('formate correctement un score en millions', () {
        expect(GameFormatters.formatScore(1234567), '1,2M');
      });
    });

    group('formatRank', () {
      test('formate correctement un rang', () {
        expect(GameFormatters.formatRank(1), '#1');
      });

      test('formate correctement un rang à deux chiffres', () {
        expect(GameFormatters.formatRank(10), '#10');
      });
    });

    group('formatPlayerName', () {
      test('ne modifie pas un nom court', () {
        expect(GameFormatters.formatPlayerName('John'), 'John');
      });

      test('tronque un nom long', () {
        expect(
          GameFormatters.formatPlayerName('John Doe Smith Johnson'),
          'John Doe Smith Johns...',
        );
      });
    });

    group('formatAchievementName', () {
      test('formate correctement un nom de succès', () {
        expect(
          GameFormatters.formatAchievementName('FIRST_PAPERCLIP'),
          'First Paperclip',
        );
      });

      test('formate correctement un nom de succès avec plusieurs mots', () {
        expect(
          GameFormatters.formatAchievementName('MASTER_PAPERCLIP_MAKER'),
          'Master Paperclip Maker',
        );
      });
    });

    group('formatProductionRate', () {
      test('formate correctement un taux de production', () {
        expect(GameFormatters.formatProductionRate(1.5), '1.5/s');
      });

      test('formate correctement un taux de production nul', () {
        expect(GameFormatters.formatProductionRate(0), '0.0/s');
      });
    });

    group('formatEfficiency', () {
      test('formate correctement une efficacité', () {
        expect(GameFormatters.formatEfficiency(0.75), '75.0%');
      });

      test('formate correctement une efficacité nulle', () {
        expect(GameFormatters.formatEfficiency(0), '0.0%');
      });

      test('formate correctement une efficacité maximale', () {
        expect(GameFormatters.formatEfficiency(1), '100.0%');
      });
    });

    group('formatQuality', () {
      test('formate correctement une qualité', () {
        expect(GameFormatters.formatQuality(0.75), '75.0%');
      });

      test('formate correctement une qualité nulle', () {
        expect(GameFormatters.formatQuality(0), '0.0%');
      });

      test('formate correctement une qualité maximale', () {
        expect(GameFormatters.formatQuality(1), '100.0%');
      });
    });
  });
} 