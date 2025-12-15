import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/market_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MarketScreen se construit avec GameState provider', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: MarketScreen())),
      ),
    );

    expect(find.byType(MarketScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });

  testWidgets('MarketScreen - bouton + augmente le prix de vente (sellPrice)', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    final sellPriceBefore = gameState.player.sellPrice;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: MarketScreen())),
      ),
    );

    // Le premier + correspond au contrôle du prix de vente.
    final plusButton = find.byIcon(Icons.add).first;
    expect(plusButton, findsOneWidget);

    await tester.tap(plusButton);
    await tester.pump();

    expect(gameState.player.sellPrice, greaterThan(sellPriceBefore));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });
}
