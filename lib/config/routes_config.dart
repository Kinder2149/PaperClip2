import 'package:flutter/material.dart';
import '../screens/screens.dart';

class RoutesConfig {
  static const String initial = '/';
  static const String home = '/home';
  static const String start = '/start';
  static const String production = '/production';
  static const String market = '/market';
  static const String upgrades = '/upgrades';
  static const String saveLoad = '/save-load';
  static const String eventLog = '/event-log';
  static const String introduction = '/introduction';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => const LoadingScreen(),
    home: (context) => const HomeScreen(),
    start: (context) => const StartScreen(),
    production: (context) => const ProductionScreen(),
    market: (context) => const MarketScreen(),
    upgrades: (context) => const UpgradesScreen(),
    saveLoad: (context) => const SaveLoadScreen(),
    eventLog: (context) => const EventLogScreen(),
    introduction: (context) => const IntroductionScreen(),
  };
} 