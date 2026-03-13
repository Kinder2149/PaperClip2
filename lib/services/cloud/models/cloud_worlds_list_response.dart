import 'package:json_annotation/json_annotation.dart';
import 'cloud_world_list_item.dart';

part 'cloud_worlds_list_response.g.dart';

@JsonSerializable()
class CloudWorldsListResponse {
  final List<CloudWorldListItem> items;
  final int page;
  final int limit;
  final int? total;

  CloudWorldsListResponse({
    required this.items,
    required this.page,
    required this.limit,
    this.total,
  });

  factory CloudWorldsListResponse.fromJson(Map<String, dynamic> json) =>
      _$CloudWorldsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CloudWorldsListResponseToJson(this);
}
