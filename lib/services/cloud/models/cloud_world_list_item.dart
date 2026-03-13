import 'package:json_annotation/json_annotation.dart';

part 'cloud_world_list_item.g.dart';

@JsonSerializable()
class CloudWorldListItem {
  @JsonKey(name: 'world_id')
  final String worldId;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  final String? name;

  @JsonKey(name: 'game_version')
  final String? gameVersion;

  CloudWorldListItem({
    required this.worldId,
    this.updatedAt,
    this.name,
    this.gameVersion,
  });

  factory CloudWorldListItem.fromJson(Map<String, dynamic> json) =>
      _$CloudWorldListItemFromJson(json);

  Map<String, dynamic> toJson() => _$CloudWorldListItemToJson(this);

  DateTime? get updatedAtDateTime {
    if (updatedAt == null) return null;
    return DateTime.tryParse(updatedAt!);
  }
}
