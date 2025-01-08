class SaveModel {
  int paperclipsCreated;
  int paperclipsInStock;
  double money;
  double metal;

  SaveModel({
    required this.paperclipsCreated,
    required this.paperclipsInStock,
    required this.money,
    required this.metal,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'paperclipsCreated': paperclipsCreated,
    'paperclipsInStock': paperclipsInStock,
    'money': money,
    'metal': metal,
  };

  // Create from JSON
  factory SaveModel.fromJson(Map<String, dynamic> json) {
    return SaveModel(
      paperclipsCreated: json['paperclipsCreated'],
      paperclipsInStock: json['paperclipsInStock'],
      money: json['money'],
      metal: json['metal'],
    );
  }
}