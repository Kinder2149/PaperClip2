// lib/data/repositories/game_repository_impl.dart
import 'package:paperclip2/domain/repositories/game_repository.dart';
import 'package:paperclip2/domain/entities/game_state_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state_model.dart';
import 'dart:convert';

class GameRepositoryImpl implements GameRepository {
  final SharedPreferences _prefs;
  static const String _savePrefix = 'paperclip_save_';

  GameRepositoryImpl(this._prefs);

  @override
  Future<void> saveGame(String name, GameStateEntity gameState) async {
    final model = GameStateModel.fromEntity(gameState);
    await _prefs.setString(_getKey(name), json.encode(model.toJson()));
  }

  @override
  Future<GameStateEntity?> loadGame(String name) async {
    final savedData = _prefs.getString(_getKey(name));
    if (savedData == null) {
      return null;
    }

    try {
      final jsonData = json.decode(savedData);
      final model = GameStateModel.fromJson(jsonData);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SaveGameInfo>> listSaves() async {
    final saves = <SaveGameInfo>[];

    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_savePrefix)) {
        try {
          final savedData = _prefs.getString(key) ?? '{}';
          final data = json.decode(savedData);
          final model = GameStateModel.fromJson(data);

          saves.add(SaveGameInfo(
            name: key.substring(_savePrefix.length),
            timestamp: model.timestamp,
            paperclips: model.player.paperclips,
            money: model.player.money,
            gameMode: model.gameMode,
          ));
        } catch (e) {
          // Ignorer les sauvegardes corrompues
        }
      }
    }

    // Trier par date de sauvegarde (plus récent d'abord)
    saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return saves;
  }

  @override
  Future<bool> deleteSave(String name) async {
    return await _prefs.remove(_getKey(name));
  }

  String _getKey(String name) {
    return '$_savePrefix$name';
  }
}