import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/game_actions.dart';

class TestHarness extends StatelessWidget {
  final Widget child;
  final GameState gameState;

  const TestHarness({super.key, required this.child, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: gameState),
        Provider<GameActions>(create: (_) => GameActions(gameState: gameState)),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }
}
