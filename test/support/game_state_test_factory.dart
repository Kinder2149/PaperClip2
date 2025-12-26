import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

class TestGameState extends GameState {
  final String _pid;
  final String _name;
  TestGameState(this._pid, this._name);

  @override
  bool get isInitialized => true;

  @override
  String? get partieId => _pid;

  @override
  String? get gameName => _name;

  @override
  GameSnapshot toSnapshot() => GameSnapshot(
        metadata: {
          'snapshotSchemaVersion': 1,
          'lastActiveAt': DateTime.now().toIso8601String(),
        },
        core: const {
          'paperclips': 0,
          'money': 0.0,
        },
        market: const {},
        production: const {},
        stats: const {},
      );

  @override
  void markLastSaveTime(DateTime _t) {
    // no-op in tests
  }
}

class GameStateTestFactory {
  static GameState newInitialized({required String partieId, String? name}) {
    return TestGameState(partieId, name ?? partieId);
  }
}
