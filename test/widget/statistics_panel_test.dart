import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/reset_history_entry.dart';
import 'package:paperclip2/screens/panels/statistics_panel.dart';

/// Tests pour StatisticsPanel
void main() {
  group('StatisticsPanel Widget', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      // Attendre initialisation
      while (!gameState.isInitialized) {}
    });

    testWidgets('affiche le titre Statistiques', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('affiche les statistiques de production', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.text('Production'), findsOneWidget);
      expect(find.text('Trombones produits (total)'), findsOneWidget);
      expect(find.text('Trombones manuels'), findsOneWidget);
    });

    testWidgets('affiche les statistiques économiques', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.text('Économie'), findsOneWidget);
      expect(find.text('Argent gagné (total)'), findsOneWidget);
      expect(find.text('Argent dépensé'), findsOneWidget);
    });

    testWidgets('affiche le temps de jeu', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.text('Temps de jeu'), findsOneWidget);
      // Format HH:MM:SS devrait être présent
      expect(find.textContaining('h'), findsWidgets);
    });

    testWidgets('affiche message si aucun reset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.text('Historique des Resets'), findsOneWidget);
      expect(find.text('Aucun reset effectué'), findsOneWidget);
    });

    testWidgets('affiche historique des resets si présent', (WidgetTester tester) async {
      // Ajouter un reset dans l'historique
      final resetEntry = ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );
      gameState.addResetEntry(resetEntry);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier que l'historique est affiché
      expect(find.text('Historique des Resets'), findsOneWidget);
      expect(find.text('1 reset effectué'), findsOneWidget);
      expect(find.text('Niveau 25'), findsOneWidget);
    });

    testWidgets('affiche résumé des gains totaux', (WidgetTester tester) async {
      // Ajouter plusieurs resets
      gameState.addResetEntry(ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 20,
        quantumGained: 5,
        innovationGained: 3,
      ));
      gameState.addResetEntry(ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier résumé
      expect(find.text('2 resets effectués'), findsOneWidget);
      expect(find.text('Quantum total'), findsOneWidget);
      expect(find.text('PI total'), findsOneWidget);
    });

    testWidgets('limite affichage à 5 derniers resets', (WidgetTester tester) async {
      // Ajouter 7 resets
      for (int i = 0; i < 7; i++) {
        gameState.addResetEntry(ResetHistoryEntry(
          timestamp: DateTime.now().subtract(Duration(days: i)),
          levelBefore: 20 + i,
          quantumGained: 5,
          innovationGained: 3,
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier message "et X autres"
      expect(find.textContaining('et 2 autres resets'), findsOneWidget);
    });

    testWidgets('scroll fonctionne correctement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: StatisticsPanel()),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });
  });
}
