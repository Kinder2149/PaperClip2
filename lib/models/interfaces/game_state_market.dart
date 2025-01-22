import 'package:flutter/foundation.dart';
import 'dart:async';
import '../market/market_manager.dart';
import '../market/market_dynamics.dart';
import 'package:paperclip2/models/level_system.dart'; // Ajout de l'import

mixin GameStateMarket on ChangeNotifier {
  late MarketManager marketManager;
  Timer? marketTimer; // Suppression du *

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
    marketTimer?.cancel(); // Suppression du *
    marketTimer = Timer.periodic( // Suppression du *
      const Duration(milliseconds: 500),
          (timer) => processMarket(),
    );
  }

  void processMarket();
  int getMarketingLevel();
  Timer? get marketTimerGetter => marketTimer;
}