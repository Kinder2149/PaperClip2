// lib/models/interfaces/game_state_production.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../constants.dart';
import '../upgrade.dart';

mixin GameStateProduction on ChangeNotifier {  // Ajout de "on ChangeNotifier"
  Timer? _productionTimer;  // Renommé pour éviter les conflits

  // Getters abstraits qui seront implémentés dans GameState
  double get metal;
  set metal(double value);
  int get autoclippers;
  double get paperclips;
  set paperclips(double value);
  Map<String, Upgrade> get upgrades;

  void startProductionTimer() {
    _productionTimer?.cancel();
    _productionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) => processProduction(),
    );
  }

  void processProduction();  // Méthode abstraite

  // Ajout du getter pour l'accès depuis GameState
  Timer? get productionTimer => _productionTimer;
}