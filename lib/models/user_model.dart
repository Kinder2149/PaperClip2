import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  final String id;
  final String? username;
  final String? email;

  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'email_verified')
  final bool emailVerified;

  final String? provider;

  @JsonKey(name: 'xp_total')
  final int xpTotal;

  final int level;

  @JsonKey(name: 'games_played')
  final int gamesPlayed;

  @JsonKey(name: 'highest_score')
  final int highestScore;
  
  @JsonKey(name: 'is_admin') // Ajout pour correspondre à la logique existante dans AuthService
  final bool isAdmin;

  UserModel({
    required this.id,
    this.username,
    this.email,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.emailVerified,
    this.provider,
    required this.xpTotal,
    required this.level,
    required this.gamesPlayed,
    required this.highestScore,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
