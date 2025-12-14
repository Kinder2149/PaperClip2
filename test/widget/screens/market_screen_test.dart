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
}
