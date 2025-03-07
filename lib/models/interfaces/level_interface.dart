import '../types/game_types.dart';

abstract class ILevel {
  int get level;
  int get experience;
  int get experienceForNextLevel;
  double get levelProgress;
  bool get hasUnlockedFeature(UnlockableFeature feature);
  List<UnlockableFeature> get unlockedFeatures;

  void addExperience(int amount);
  void addAutomaticProduction(int amount);
  void addManualProduction();
  void addAutoclipperPurchase();
  void addStorageUpgrade();
  void addMarketingUpgrade();
  void addEfficiencyUpgrade();
  void addQualityUpgrade();
  Map<String, dynamic> toJson();
  
  factory ILevel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by the concrete class');
  }
}
 