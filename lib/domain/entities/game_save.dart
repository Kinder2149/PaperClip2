import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_save.freezed.dart';
part 'game_save.g.dart';

@freezed
class GameSave with _$GameSave {
  const factory GameSave({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime lastPlayed,
    required Map<String, dynamic> gameState,
  }) = _GameSave;

  factory GameSave.fromJson(Map<String, dynamic> json) => _$GameSaveFromJson(json);
} 