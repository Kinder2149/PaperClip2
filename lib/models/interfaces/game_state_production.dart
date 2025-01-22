import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:paperclip2/models/constants.dart';
import '../upgrade.dart';

mixin GameStateProduction on ChangeNotifier {
  Timer? productionTimer; // Suppression du *

  double get metal;
  set metal(double value);
  int get autoclippers;
  double get paperclips;
  set paperclips(double value);
  Map<String, Upgrade> get upgrades;

  void startProductionTimer() {
    productionTimer?.cancel(); // Suppression du *
    productionTimer = Timer.periodic( // Suppression du *
      const Duration(seconds: 1),
          (timer) => processProduction(),
    );
  }

  void processProduction();
  Timer? get productionTimerGetter => productionTimer; // Renommé
}