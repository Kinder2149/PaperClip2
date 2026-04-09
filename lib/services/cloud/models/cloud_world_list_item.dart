import 'package:json_annotation/json_annotation.dart';

part 'cloud_world_list_item.g.dart';

@JsonSerializable()
class CloudWorldListItem {
  @JsonKey(name: 'enterprise_id')
  final String enterpriseId;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  final String? name;

  @JsonKey(name: 'game_version')
  final String? gameVersion;

  CloudWorldListItem({
    required this.enterpriseId,
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
