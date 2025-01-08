// lib/models/interfaces/game_state_market.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../market/market_manager.dart';
import '../market/market_dynamics.dart';

mixin GameStateMarket on ChangeNotifier {  // Ajout de "on ChangeNotifier"
  late MarketManager marketManager;
  Timer? _marketTimer;  // Renommé pour éviter les conflits

  double get sellPrice;
  set sellPrice(double value);
  double get metal;
  double get money;
  double get paperclips;
  set paperclips(double value);

  void initializeMarket() {
    marketManager = MarketManager(MarketDynamics());
    startMarketTimer();
  }

  void startMarketTimer() {
    _marketTimer?.cancel();
    _marketTimer = Timer.periodic(
      const Duration(milliseconds: 500),
          (timer) => processMarket(),
    );
  }

  void processMarket();
  int getMarketingLevel();

  // Ajout du getter pour l'accès depuis GameState
  Timer? get marketTimer => _marketTimer;
}