// test/local_save/save_button_widget_test.dart
// Test : SaveButton widget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/widgets/save_button.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Test SaveButton Widget', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('SaveButton affiche correctement avec entreprise initialisée', (tester) async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Button Test');
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Vérifier que le bouton est affiché
      expect(find.byType(SaveButton), findsOneWidget);
      expect(find.text('Sauvegarder'), findsOneWidget);
    });

    testWidgets('SaveButton ne s\'affiche pas si jeu non initialisé', (tester) async {
      final gameState = GameState();
      // Ne pas créer d'entreprise
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Le bouton ne devrait pas être affiché
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('SaveButton déclenche sauvegarde au tap', (tester) async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Tap Test');
      
      gameState.playerManager.addPaperclips(123);
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Trouver et tapper le bouton
      final button = find.text('Sauvegarder');
      expect(button, findsOneWidget);
      
      await tester.tap(button);
      await tester.pumpAndSettle();
      
      // Vérifier que la sauvegarde a été effectuée
      final orchestrator = GamePersistenceOrchestrator.instance;
      final saves = await orchestrator.listSaves();
      expect(saves, isNotEmpty);
      
      // Charger et vérifier les données
      final newGameState = GameState();
      await orchestrator.loadGameById(newGameState, gameState.enterpriseId!);
      expect(newGameState.playerManager.paperclips, equals(123.0));
    });

    testWidgets('SaveButton affiche état de chargement pendant sauvegarde', (tester) async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Loading Test');
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tapper le bouton
      await tester.tap(find.text('Sauvegarder'));
      await tester.pump(); // Pump une fois pour déclencher l'état de chargement
      
      // Vérifier qu'un indicateur de chargement est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle(); // Attendre la fin de la sauvegarde
    });

    testWidgets('SaveButton IconOnly affiche correctement', (tester) async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Icon Test');
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(isIconOnly: true),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Vérifier qu'un IconButton est affiché
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('SaveButton FloatingActionButton affiche correctement', (tester) async {
      final gameState = GameState();
      await gameState.createNewEnterprise('FAB Test');
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameState,
          child: const MaterialApp(
            home: Scaffold(
              body: SaveButton(isFloatingActionButton: true),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Vérifier qu'un FAB est affiché
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });
}
