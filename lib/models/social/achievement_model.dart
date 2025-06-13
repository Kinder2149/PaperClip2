import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AchievementModel {
  final String id;
  final String name;
  final String description;

  @JsonKey(name: 'icon_url')
  final String? iconUrl;

  final int? points;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.points,
    this.isActive,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => _$AchievementModelFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementModelToJson(this);
}

// Modèle pour la création d'un succès (envoyé au backend)
@JsonSerializable()
class AchievementCreateModel {
  final String name;
  final String description;

  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  
  final int? points;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  AchievementCreateModel({
    required this.name,
    required this.description,
    this.iconUrl,
    this.points,
    this.isActive,
  });

  factory AchievementCreateModel.fromJson(Map<String, dynamic> json) => _$AchievementCreateModelFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementCreateModelToJson(this);
}
