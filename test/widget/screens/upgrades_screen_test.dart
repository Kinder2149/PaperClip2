import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/upgrades_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UpgradesScreen se construit avec GameState provider', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: UpgradesScreen())),
      ),
    );

    expect(find.byType(UpgradesScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });

  testWidgets('UpgradesScreen - affiche l\'écran verrouillé au niveau initial', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: UpgradesScreen())),
      ),
    );

    expect(find.text('Améliorations verrouillées'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });

  testWidgets('UpgradesScreen - déverrouille et permet d\'acheter une amélioration', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final gameState = GameState();
    gameState.initialize();

    // Déverrouiller la section upgrades (niveau >= UPGRADES_UNLOCK_LEVEL) sans déclencher
    // de level-up "réel" (sinon LevelSystem peut créer un timer d'XP boost de 5 minutes).
    gameState.levelSystem.fromJson(<String, dynamic>{
      'experience': 0,
      'level': GameConstants.UPGRADES_UNLOCK_LEVEL,
      'currentPath': 0,
      'xpMultiplier': 1.0,
      'comboCount': 0,
      'dailyBonusClaimed': false,
      'pathProgress': <String, dynamic>{},
      'unlockedMilestones': <String, dynamic>{},
      'pendingPathChoiceLevel': null,
      'pendingPathOptions': <dynamic>[],
    });

    // Les changements de LevelSystem ne notifient pas directement GameState; on force
    // un rebuild via un tick métier (qui appelle notifyListeners).
    gameState.tick(elapsedSeconds: 0.1);

    expect(
      gameState.levelSystem.level,
      greaterThanOrEqualTo(GameConstants.UPGRADES_UNLOCK_LEVEL),
    );

    // Donner assez d'argent pour acheter.
    gameState.playerManager.updateMoney(100000.0);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: UpgradesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Améliorations verrouillées'), findsNothing);
    expect(find.text('Efficacité'), findsWidgets);

    const targetUpgradeId = 'efficiency';
    final levelBefore = gameState.player.upgrades[targetUpgradeId]!.level;
    final moneyBefore = gameState.player.money;

    // S'assurer que la carte "Efficacité" est bien visible (ListView).
    final efficiencyLabel = find.text('Efficacité').last;
    await tester.ensureVisible(efficiencyLabel);
    await tester.pumpAndSettle();

    final buyLabels = find.text('Acheter');
    expect(buyLabels, findsWidgets);

    await tester.tap(buyLabels.first);
    await tester.pumpAndSettle();

    // Certaines notifications utilisent Future.delayed (3s) via EventManager.
    // On avance le temps pour vider ces timers et éviter un échec "timersPending".
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(gameState.player.upgrades[targetUpgradeId]!.level, levelBefore + 1);
    expect(gameState.player.money, lessThan(moneyBefore));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });
}
