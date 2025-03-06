import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/game_save.dart';
import '../../domain/repositories/save_repository.dart';
import '../../domain/repositories/player_repository.dart';

class SaveRepositoryImpl implements SaveRepository {
  final SharedPreferences _prefs;
  final PlayerRepository _playerRepository;
  static const String _savesKey = 'game_saves';

  SaveRepositoryImpl(this._prefs, this._playerRepository);

  @override
  Future<List<GameSave>> getAvailableSaves() async {
    final String? savesJson = _prefs.getString(_savesKey);
    if (savesJson == null) return [];

    final List<dynamic> savesList = jsonDecode(savesJson);
    return savesList.map((json) => GameSave.fromJson(json)).toList();
  }

  @override
  Future<GameSave?> getSave(String id) async {
    final saves = await getAvailableSaves();
    return saves.firstWhere(
      (save) => save.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> createSave(GameSave save) async {
    final saves = await getAvailableSaves();
    saves.add(save);
    await _saveSaves(saves);
  }

  @override
  Future<void> updateSave(GameSave save) async {
    final saves = await getAvailableSaves();
    final index = saves.indexWhere((s) => s.id == save.id);
    if (index != -1) {
      saves[index] = save;
      await _saveSaves(saves);
    }
  }

  @override
  Future<void> deleteSave(String id) async {
    final saves = await getAvailableSaves();
    saves.removeWhere((save) => save.id == id);
    await _saveSaves(saves);
  }

  @override
  Future<void> saveCurrentGame(String name) async {
    final playerState = await _playerRepository.getPlayerState();
    if (playerState == null) return;

    final save = GameSave(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      lastPlayed: DateTime.now(),
      gameState: playerState.toJson(),
    );

    await createSave(save);
  }

  @override
  Future<void> loadGame(String id) async {
    final save = await getSave(id);
    if (save == null) return;

    await _playerRepository.updatePlayerState(save.gameState);
  }

  Future<void> _saveSaves(List<GameSave> saves) async {
    final savesJson = saves.map((save) => save.toJson()).toList();
    await _prefs.setString(_savesKey, jsonEncode(savesJson));
  }
} 