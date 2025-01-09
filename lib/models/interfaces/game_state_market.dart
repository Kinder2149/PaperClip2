import 'package:flutter/foundation.dart';
import 'dart:async';
import '../market/market_manager.dart';
import '../market/market_dynamics.dart';

mixin GameStateMarket on ChangeNotifier {
  late MarketManager marketManager;
  Timer? _marketTimer;

  // Getters et setters abstraits
  double get sellPrice;
  set sellPrice(double value);
  double get metal;
  double get money;
  double get paperclips;
  set paperclips(double value);

  // Méthodes abstraites
  void processMarket();
  int getMarketingLevel();

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

  // Getter pour l'accès au timer
  Timer? get marketTimer => _marketTimer;
}