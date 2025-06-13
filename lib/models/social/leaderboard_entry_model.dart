import 'package:json_annotation/json_annotation.dart';
// Potentiellement, importer UserModel pour les détails de l'utilisateur
// import '../user_model.dart';

part 'leaderboard_entry_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LeaderboardEntryModel {
  final String id;

  @JsonKey(name: 'leaderboard_id')
  final String leaderboardId;

  @JsonKey(name: 'user_id')
  final String userId;
  
  final int score;
  final int? rank;
  final DateTime timestamp;

  // TODO: Envisager d'ajouter un champ UserModel pour les détails de l'utilisateur
  // final UserModel? user;

  LeaderboardEntryModel({
    required this.id,
    required this.leaderboardId,
    required this.userId,
    required this.score,
    this.rank,
    required this.timestamp,
    // this.user,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryModelToJson(this);
}

// Modèle pour la création d'une entrée de classement (envoyé au backend)
@JsonSerializable()
class LeaderboardEntryCreateModel {
  @JsonKey(name: 'leaderboard_id')
  final String leaderboardId;
  final int score;

  LeaderboardEntryCreateModel({
    required this.leaderboardId,
    required this.score,
  });

  factory LeaderboardEntryCreateModel.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryCreateModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryCreateModelToJson(this);
}
