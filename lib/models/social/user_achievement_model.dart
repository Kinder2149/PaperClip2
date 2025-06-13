import 'package:json_annotation/json_annotation.dart';
// Potentiellement, importer AchievementModel pour les détails du succès
// import './achievement_model.dart'; 

part 'user_achievement_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserAchievementModel {
  final String id;

  @JsonKey(name: 'achievement_id')
  final String achievementId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'unlocked_at')
  final DateTime unlockedAt;

  // TODO: Envisager d'ajouter un champ AchievementModel pour les détails du succès
  // final AchievementModel? achievement;

  UserAchievementModel({
    required this.id,
    required this.achievementId,
    required this.userId,
    required this.unlockedAt,
    // this.achievement,
  });

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) => _$UserAchievementModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserAchievementModelToJson(this);
}

// Modèle pour la création/déblocage d'un succès utilisateur (envoyé au backend)
@JsonSerializable()
class UserAchievementCreateModel {
  @JsonKey(name: 'achievement_id')
  final String achievementId;

  UserAchievementCreateModel({required this.achievementId});

  factory UserAchievementCreateModel.fromJson(Map<String, dynamic> json) => _$UserAchievementCreateModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserAchievementCreateModelToJson(this);
}
