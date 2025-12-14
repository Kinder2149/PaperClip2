import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/production_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProductionScreen se construit avec GameState provider', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: Scaffold(body: ProductionScreen())),
      ),
    );

    expect(find.byType(ProductionScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });
}
