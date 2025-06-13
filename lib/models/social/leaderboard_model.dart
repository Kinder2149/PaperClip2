import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LeaderboardModel {
  final String id;
  final String name;
  final String? description;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  LeaderboardModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive,
    required this.createdAt,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) => _$LeaderboardModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardModelToJson(this);
}

// Modèle pour la création d'un classement (envoyé au backend)
@JsonSerializable()
class LeaderboardCreateModel {
  final String name;
  final String? description;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  LeaderboardCreateModel({
    required this.name,
    this.description,
    this.isActive,
  });

  factory LeaderboardCreateModel.fromJson(Map<String, dynamic> json) => _$LeaderboardCreateModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardCreateModelToJson(this);
}
