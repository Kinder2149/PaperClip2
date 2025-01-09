import 'package:flutter/foundation.dart';
import 'dart:async';
import '../constants.dart';
import '../upgrade.dart';

mixin GameStateProduction on ChangeNotifier {
  Timer? _productionTimer;

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

  void processProduction();

  Timer? get productionTimer => _productionTimer;
}