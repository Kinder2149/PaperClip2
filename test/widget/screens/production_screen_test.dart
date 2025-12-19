import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/production_screen.dart';
import '../../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProductionScreen se construit avec GameState provider', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(TestHarness(child: const ProductionScreen(), gameState: gameState));

    expect(find.byType(ProductionScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });

  testWidgets('ProductionScreen - toggle Vente automatique met Ã  jour GameState', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final gameState = GameState();
    gameState.initialize();

    await tester.pumpWidget(TestHarness(child: const ProductionScreen(), gameState: gameState));

    final toggle = find.widgetWithText(SwitchListTile, 'Vente automatique');
    expect(toggle, findsOneWidget);

    final before = tester.widget<SwitchListTile>(toggle).value;

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final after = tester.widget<SwitchListTile>(toggle).value;
    expect(after, isNot(before));
    expect(gameState.autoSellEnabled, after);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    gameState.dispose();
  });
}
