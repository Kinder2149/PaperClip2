// lib/services/save/save_data_provider.dart
import '../../models/game_config.dart';

abstract class SaveDataProvider {
  Map<String, dynamic> prepareGameData();
  void loadGameData(Map<String, dynamic> data);
  String? get gameName;
  GameMode get gameMode;
}