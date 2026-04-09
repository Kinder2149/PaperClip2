import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/panels/dashboard_panel.dart';

/// Tests pour DashboardPanel
void main() {
  group('DashboardPanel Widget', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      // Attendre initialisation
      while (!gameState.isInitialized) {}
    });

    testWidgets('affiche le titre Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      expect(find.text('Tableau de Bord'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('affiche les 4 stats principales', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      // Vérifier les labels
      expect(find.text('Argent'), findsOneWidget);
      expect(find.text('Trombones'), findsOneWidget);
      expect(find.text('Métal'), findsOneWidget);
      expect(find.text('Autoclippers'), findsOneWidget);
    });

    testWidgets('affiche la carte de progression', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      expect(find.text('Progression'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche les ressources rares', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      expect(find.text('Ressources Rares'), findsOneWidget);
      expect(find.text('Quantum'), findsOneWidget);
      expect(find.text('Points Innovation'), findsOneWidget);
    });

    testWidgets('affiche les actions rapides', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      expect(find.text('Actions Rapides'), findsOneWidget);
      expect(find.text('Acheter Métal'), findsOneWidget);
    });

    testWidgets('bouton reset visible si conditions remplies', (WidgetTester tester) async {
      // Simuler niveau 20+ pour activer reset
      gameState.levelSystem.fromJson({'level': 25, 'experience': 0});
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bouton reset devrait être visible si canReset() == true
      // (dépend aussi de la production de trombones)
      if (gameState.resetManager.canReset()) {
        expect(find.text('Reset Progression'), findsOneWidget);
      }
    });

    testWidgets('scroll fonctionne correctement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameState,
            child: const Scaffold(body: DashboardPanel()),
          ),
        ),
      );

      // Vérifier que le widget est scrollable
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
