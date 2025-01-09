import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/save_manager.dart';

mixin GameStateSave on ChangeNotifier {
  // Méthodes abstraites pour la gestion des sauvegardes
  Future<Map<String, dynamic>> prepareGameData();
  void _loadGameData(Map<String, dynamic> gameData);

  Future<void> saveGame([String? gameName]);
  Future<void> loadGame(String gameId);
  Future<void> startNewGame(String gameName);
  Future<List<Map<String, dynamic>>> listGames();
  Future<void> deleteGame(String gameId);
  void startAutoSave(BuildContext context);
}