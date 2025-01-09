import 'package:flutter/foundation.dart';
import 'dart:async';
import '../market/market_manager.dart';
import '../market/market_dynamics.dart';

mixin GameStateMarket on ChangeNotifier {
  late MarketManager marketManager;
  Timer? _marketTimer;

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

  Timer? get marketTimer => _marketTimer;
}