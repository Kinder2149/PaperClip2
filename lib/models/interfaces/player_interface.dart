import '../upgrade.dart';

abstract class IPlayer {
  int get paperclips;
  int get money;
  int get experience;
  int get totalPaperclips;
  double get productionMultiplier;
  double get autoProductionRate;
  bool get hasAutoClipper;
  bool get hasMarketAccess;
  bool get hasUpgradesAccess;

  void addPaperclips(int amount);
  void spendMoney(int amount);
  void addMoney(int amount);
  void addExperience(int amount);
  int producePaperclip();
  Map<String, dynamic> toJson();
  
  factory IPlayer.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by the concrete class');
  }
} 