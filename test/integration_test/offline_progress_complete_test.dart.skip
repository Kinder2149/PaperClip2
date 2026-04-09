import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Test d'intégration complet du système de progression offline
/// 
/// Ce test vérifie le cycle complet de la progression offline :
/// 1. L'utilisateur quitte l'app (enregistrement du lastActiveAt)
/// 2. Le temps passe (simulation)
/// 3. L'utilisateur revient (calcul et application de la progression)
/// 4. Vérification des gains (trombones, argent)
/// 5. Vérification des limites (cap 120min, seuil notification)
void main() {
  group('🔄 Offline Progress - Cycle Complet', () {
    late GameState gameState;
    
    setUp(() async {
      gameState = GameState();
      await gameState.createNewEnterprise('Test Offline Corp');
    });

    test('TEST 1: ✅ Absence de 10 minutes avec autoclippers', () {
      // ARRANGE: Configurer l'état initial
      gameState.productionManager.buyAutoclipper(); // Acheter 1 autoclipper
      gameState.setAutoSellEnabled(false);
      
      final initialPaperclips = gameState.playerManager.paperclips;
      
      // Simuler le départ de l'utilisateur
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      
      // ACT: Simuler 10 minutes d'absence
      final retourTime = DateTime(2024, 1, 1, 12, 10, 0);
      
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Vérifier que la progression offline a été appliquée
      expect(result.didSimulate, isTrue, 
        reason: 'Une simulation doit avoir été effectuée');
      
      expect(result.absenceDuration.inMinutes, equals(10),
        reason: 'La durée d\'absence doit être de 10 minutes');
      
      expect(result.paperclipsProduced, greaterThan(0),
        reason: 'Des trombones doivent avoir été produits pendant l\'absence');
      
      expect(gameState.playerManager.paperclips, greaterThan(initialPaperclips),
        reason: 'Le stock de trombones doit avoir augmenté');
      
      expect(result.wasCapped, isFalse,
        reason: '10 minutes est en dessous du cap de 120 minutes');
    });

    test('TEST 2: ✅ Absence de 10 minutes AVEC vente auto', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      gameState.setAutoSellEnabled(true); // Vente auto activée
      
      final initialMoney = gameState.playerManager.money;
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 10, 0);
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: L'argent doit avoir augmenté grâce à la vente auto
      expect(result.didSimulate, isTrue);
      expect(result.moneyEarned, greaterThan(0),
        reason: 'De l\'argent doit avoir été gagné avec la vente auto');
      
      expect(gameState.playerManager.money, greaterThan(initialMoney),
        reason: 'Le solde doit avoir augmenté');
    });

    test('TEST 3: ⚠️ Cap à 120 minutes - Absence de 4 heures', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      gameState.setAutoSellEnabled(false);
      
      final departTime = DateTime(2024, 1, 1, 8, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 0, 0); // 4 heures = 240 minutes
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: La durée d'absence réelle est 4 heures
      expect(result.absenceDuration.inMinutes, equals(240),
        reason: 'La durée d\'absence réelle doit être 240 minutes');
      
      // ASSERT: Le flag wasCapped doit être true
      expect(result.wasCapped, isTrue,
        reason: 'La production doit être cappée au-delà de 120 minutes');
      
      // ASSERT: La production doit être limitée à 120 minutes max
      expect(result.didSimulate, isTrue);
      expect(result.paperclipsProduced, greaterThan(0));
    });

    test('TEST 4: 🚫 Seuil de notification - Absence < 60 secondes', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 0, 30); // 30 secondes
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Le résultat existe mais la durée est < 60s
      expect(result.absenceDuration.inSeconds, lessThan(60),
        reason: 'L\'absence doit être inférieure à 60 secondes');
      
      // Dans l'app réelle, la notification ne s'afficherait pas
      // car le seuil est de 60 secondes (voir main_screen.dart ligne 82)
    });

    test('TEST 5: ✅ Seuil de notification - Absence >= 60 secondes', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 1, 30); // 90 secondes
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Le résultat existe et la durée est >= 60s
      expect(result.absenceDuration.inSeconds, greaterThanOrEqualTo(60),
        reason: 'L\'absence doit être >= 60 secondes pour déclencher la notification');
      
      expect(result.didSimulate, isTrue,
        reason: 'Une simulation doit avoir été effectuée');
    });

    test('TEST 6: 🚫 Pas de production sans autoclippers', () {
      // ARRANGE: Aucun autoclipper acheté
      gameState.setAutoSellEnabled(false);
      
      final initialPaperclips = gameState.playerManager.paperclips;
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 10, 0); // 10 minutes
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Aucune production (pas d'autoclippers)
      expect(result.paperclipsProduced, equals(0.0),
        reason: 'Sans autoclippers, aucune production offline ne doit avoir lieu');
      
      expect(gameState.playerManager.paperclips, equals(initialPaperclips),
        reason: 'Le stock ne doit pas changer');
    });

    test('TEST 7: ⚠️ Delta négatif - Horloge système en arrière', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 11, 55, 0); // 5 minutes AVANT
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Aucune simulation ne doit être effectuée
      expect(result.didSimulate, isFalse,
        reason: 'Aucune simulation ne doit être faite avec un delta négatif');
      
      expect(result.paperclipsProduced, equals(0.0),
        reason: 'Aucune production ne doit être comptée');
    });

    test('TEST 8: 📊 Vérifier la structure complète du résultat', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      gameState.setAutoSellEnabled(true);
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final retourTime = DateTime(2024, 1, 1, 12, 10, 0);
      
      // ACT
      final result = gameState.applyOfflineWithService(
        now: retourTime,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      // ASSERT: Tous les champs du résultat doivent être présents
      expect(result.lastActiveAt, isNotNull);
      expect(result.lastOfflineAppliedAt, isNotNull);
      expect(result.offlineSpecVersion, equals('v2'));
      expect(result.didSimulate, isTrue);
      expect(result.absenceDuration.inMinutes, equals(10));
      expect(result.paperclipsProduced, greaterThan(0));
      expect(result.moneyEarned, greaterThan(0)); // Vente auto activée
      expect(result.wasCapped, isFalse); // < 120 minutes
    });

    test('TEST 9: 🔄 Vérifier que lastOfflineAppliedAt est pris en compte', () {
      // ARRANGE
      gameState.productionManager.buyAutoclipper();
      
      final departTime = DateTime(2024, 1, 1, 12, 0, 0);
      final premierRetour = DateTime(2024, 1, 1, 12, 5, 0);
      
      // Premier retour
      final result1 = gameState.applyOfflineWithService(
        now: premierRetour,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: null,
      );
      
      expect(result1.didSimulate, isTrue);
      final paperclipsApres1 = gameState.playerManager.paperclips;
      
      // Deuxième retour immédiat (sans nouvelle absence)
      final deuxiemeRetour = DateTime(2024, 1, 1, 12, 5, 1); // 1 seconde après
      
      final result2 = gameState.applyOfflineWithService(
        now: deuxiemeRetour,
        lastActiveAt: departTime,
        lastOfflineAppliedAt: result1.lastOfflineAppliedAt,
      );
      
      // ASSERT: Très peu ou pas de production (seulement 1 seconde)
      expect(result2.absenceDuration.inSeconds, lessThan(5),
        reason: 'La durée doit être calculée depuis lastOfflineAppliedAt');
      
      expect(gameState.playerManager.paperclips, 
        closeTo(paperclipsApres1, 2.0),
        reason: 'Très peu de production en 1 seconde');
    });

    test('TEST 10: 📈 Vérifier la constante OFFLINE_MAX_DURATION', () {
      // ASSERT: Vérifier que la constante est bien 120 minutes
      expect(GameConstants.OFFLINE_MAX_DURATION, 
        equals(const Duration(minutes: 120)),
        reason: 'La durée maximale offline doit être de 120 minutes');
      
      expect(GameConstants.OFFLINE_MAX_DURATION.inSeconds, 
        equals(7200),
        reason: '120 minutes = 7200 secondes');
    });
  });
}
