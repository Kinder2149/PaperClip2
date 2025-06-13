import 'package:json_annotation/json_annotation.dart';

part 'minimal_model.g.dart';

@JsonSerializable()
class MinimalModel {
  final String id;
  final String name;
  
  MinimalModel({
    required this.id,
    required this.name,
  });
  
  factory MinimalModel.fromJson(Map<String, dynamic> json) => _$MinimalModelFromJson(json);
  Map<String, dynamic> toJson() => _$MinimalModelToJson(this);
}
