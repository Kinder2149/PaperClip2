import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/offline_progress_service.dart';

void main() {
  group('Offline Progress Notification System - Configuration', () {
    test('TEST 1: Constante OFFLINE_MAX_DURATION est bien 120 minutes', () {
      expect(
        GameConstants.OFFLINE_MAX_DURATION,
        equals(const Duration(minutes: 120)),
        reason: 'La durée maximale offline doit être de 120 minutes (2 heures)',
      );
    });

    test('TEST 2: Vérifier que 120 minutes = 7200 secondes', () {
      expect(
        GameConstants.OFFLINE_MAX_DURATION.inSeconds,
        equals(7200),
        reason: '120 minutes doivent correspondre à 7200 secondes',
      );
    });

    test('TEST 3: Vérifier que 120 minutes != 8 heures', () {
      const oldDuration = Duration(hours: 8);
      expect(
        GameConstants.OFFLINE_MAX_DURATION,
        isNot(equals(oldDuration)),
        reason: 'La nouvelle durée ne doit plus être 8 heures',
      );
    });
  });

  group('Offline Progress Notification System - Calculs de durée', () {
    test('TEST 4: Calcul durée absence < 120 min', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 11, 0, 0); // 60 minutes
      final delta = now.difference(lastActive);

      expect(delta.inMinutes, equals(60));
      expect(delta < GameConstants.OFFLINE_MAX_DURATION, isTrue,
        reason: '60 minutes doit être inférieur à 120 minutes');
    });

    test('TEST 5: Calcul durée absence > 120 min', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 8, 0, 0); // 240 minutes
      final delta = now.difference(lastActive);

      expect(delta.inMinutes, equals(240));
      expect(delta > GameConstants.OFFLINE_MAX_DURATION, isTrue,
        reason: '240 minutes doit être supérieur à 120 minutes');
    });

    test('TEST 6: Calcul durée absence = 120 min exactement', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 10, 0, 0); // 120 minutes
      final delta = now.difference(lastActive);

      expect(delta.inMinutes, equals(120));
      expect(delta, equals(GameConstants.OFFLINE_MAX_DURATION),
        reason: '120 minutes doit être égal à OFFLINE_MAX_DURATION');
    });

    test('TEST 7: Cap à 120 min pour absence de 6 heures', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 6, 0, 0); // 360 minutes
      var delta = now.difference(lastActive);

      expect(delta.inMinutes, equals(360));

      // Simuler le cap
      if (delta > GameConstants.OFFLINE_MAX_DURATION) {
        delta = GameConstants.OFFLINE_MAX_DURATION;
      }

      expect(delta.inMinutes, equals(120),
        reason: 'La durée doit être cappée à 120 minutes');
    });

    test('TEST 8: Absence de quelques secondes', () {
      final now = DateTime(2024, 1, 1, 12, 0, 30);
      final lastActive = DateTime(2024, 1, 1, 12, 0, 0); // 30 secondes
      final delta = now.difference(lastActive);

      expect(delta.inSeconds, equals(30));
      expect(delta < GameConstants.OFFLINE_MAX_DURATION, isTrue);
    });

    test('TEST 9: Delta négatif (horloge système)', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 12, 0, 10); // Dans le futur
      final delta = now.difference(lastActive);

      expect(delta.isNegative, isTrue);
      expect(delta.inSeconds, equals(-10));
    });

    test('TEST 10: Delta zéro', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final lastActive = DateTime(2024, 1, 1, 12, 0, 0);
      final delta = now.difference(lastActive);

      expect(delta, equals(Duration.zero));
      expect(delta.inSeconds, equals(0));
    });
  });

  group('Offline Progress Notification System - Structure OfflineProgressResult', () {
    test('TEST 11: OfflineProgressResult a tous les champs requis', () {
      // Ce test vérifie que la classe compile avec tous les champs
      // Si un champ manque, le test ne compilera pas
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final result = OfflineProgressResult(
        lastActiveAt: now,
        lastOfflineAppliedAt: now,
        offlineSpecVersion: 'v2',
        didSimulate: false,
        absenceDuration: Duration.zero,
        paperclipsProduced: 0.0,
        moneyEarned: 0.0,
        wasCapped: false,
      );

      expect(result.lastActiveAt, equals(now));
      expect(result.lastOfflineAppliedAt, equals(now));
      expect(result.offlineSpecVersion, equals('v2'));
      expect(result.didSimulate, isFalse);
      expect(result.absenceDuration, equals(Duration.zero));
      expect(result.paperclipsProduced, equals(0.0));
      expect(result.moneyEarned, equals(0.0));
      expect(result.wasCapped, isFalse);
    });
  });
}
