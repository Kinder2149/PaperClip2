abstract class IUpgrade {
  String get name;
  String get description;
  double get cost;
  int get level;
  int get maxLevel;
  int get requiredLevel;

  double getCost();
  void incrementLevel();
  bool isMaxed();
  bool canPurchase(int playerMoney, int playerLevel);
  Map<String, dynamic> toJson();
  
  factory IUpgrade.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by the concrete class');
  }
} 