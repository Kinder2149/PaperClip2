import 'package:flutter/material.dart';
import '../player.dart';
import '../market.dart';
import '../level.dart';
import '../market_manager.dart';

abstract class IGameState {
  Player get player;
  Market get market;
  Level get level;
  MarketManager get marketManager;
  String? get gameName;
  int get totalPaperclipsProduced;
  int get totalTimePlayed;
  Map<String, bool> getVisibleScreenElements();
  Future<void> saveGame(String name);
  Future<void> loadGame(String name);
  void purchaseUpgrade(String id);
  void updateGameState();
  void dispose();
} 