// lib/data/datasources/local/game_data_source.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/game_state_model.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/constants/enums.dart';

abstract class GameDataSource {
  Future<GameStateModel?> getCurrentGameState();
  Future<void> saveGameState(GameStateModel gameState);
  Future<List<SaveGameInfo>> listSaves();
  Future<bool> deleteGameState(String gameName);
  Future<void> updateTotalPlayTime(int seconds);
  Future<void> startNewGame(String name, {GameMode mode});
}

class GameDataSourceImpl implements GameDataSource {
  final SharedPreferences _prefs;
  static const String _currentGameKey = 'current_game_state';
  static const String _savePrefix = 'game_save_';

  GameDataSourceImpl(this._prefs);

  @override
  Future<GameStateModel?> getCurrentGameState() async {
    final jsonString = _prefs.getString(_currentGameKey);

    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return GameStateModel.fromJson(jsonMap);
    } catch (e) {
      print('Error loading game state: $e');
      return null;
    }
  }

  @override
  Future<void> saveGameState(GameStateModel gameState) async {
    // Sauvegarde de l'état de jeu actuel
    await _prefs.setString(
        _currentGameKey,
        json.encode(gameState.toJson())
    );

    // Sauvegarde historique des parties
    final saveName = gameState.gameName ??
        '${GameConstants.DEFAULT_GAME_NAME_PREFIX}_${DateTime.now().millisecondsSinceEpoch}';

    await _prefs.setString(
        '$_savePrefix$saveName',
        json.encode(gameState.toJson())
    );
  }

  @override
  Future<List<SaveGameInfo>> listSaves() async {
    final saves = <SaveGameInfo>[];

    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_savePrefix)) {
        try {
          final savedData = _prefs.getString(key);
          if (savedData != null) {
            final gameState = GameStateModel.fromJson(json.decode(savedData));
            saves.add(SaveGameInfo(
              name: key.substring(_savePrefix.length),
              timestamp: gameState.timestamp,
              paperclips: gameState.player.paperclips,
              money: gameState.player.money,
              gameMode: gameState.gameMode,
            ));
          }
        } catch (e) {
          print('Error parsing saved game: $e');
        }
      }
    }

    // Trier par date de sauvegarde (plus récent d'abord)
    saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return saves;
  }

  @override
  Future<bool> deleteGameState(String gameName) async {
    return await _prefs.remove('$_savePrefix$gameName');
  }

  @override
  Future<void> updateTotalPlayTime(int seconds) async {
    final currentState = await getCurrentGameState();
    if (currentState != null) {
      final updatedState = currentState.copyWith(
          totalTimePlayedInSeconds: currentState.totalTimePlayedInSeconds + seconds
      );
      await saveGameState(updatedState);
    }
  }

  @override
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    // Créer un nouvel état de jeu par défaut
    final newGameState = GameStateModel(
      player: PlayerModel.fromJson({}), // Initialisation par défaut
      market: MarketModel.fromJson({}),
      level: LevelSystemModel.fromJson({}),
      statistics: StatisticsModel.fromJson({}),
      totalPaperclipsProduced: 0,
      totalTimePlayedInSeconds: 0,
      isInCrisisMode: false,
      gameMode: mode,
      version: GameConstants.VERSION,
      timestamp: DateTime.now(),
    );

    await saveGameState(newGameState);
  }
}