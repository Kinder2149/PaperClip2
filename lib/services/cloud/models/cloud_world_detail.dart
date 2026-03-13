import 'package:json_annotation/json_annotation.dart';
import '../../../constants/game_config.dart';

part 'cloud_world_detail.g.dart';

@JsonSerializable()
class CloudWorldDetail {
  @JsonKey(name: 'world_id')
  final String worldId;

  final int version;

  final Map<String, dynamic> snapshot;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  final String? name;

  @JsonKey(name: 'game_version')
  final String? gameVersion;

  @JsonKey(name: 'game_mode')
  final String? gameMode;

  CloudWorldDetail({
    required this.worldId,
    required this.version,
    required this.snapshot,
    required this.updatedAt,
    this.name,
    this.gameVersion,
    this.gameMode,
  });

  factory CloudWorldDetail.fromJson(Map<String, dynamic> json) =>
      _$CloudWorldDetailFromJson(json);

  Map<String, dynamic> toJson() => _$CloudWorldDetailToJson(this);

  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);
  
  GameMode get gameModeEnum {
    if (gameMode == null) return GameMode.INFINITE;
    return gameMode!.contains('COMPETITIVE') ? GameMode.COMPETITIVE : GameMode.INFINITE;
  }
}
