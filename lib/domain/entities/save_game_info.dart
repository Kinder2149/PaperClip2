// lib/domain/entities/save_game_info.dart
import '../../core/constants/enums.dart';

class SaveGameInfo {
  final String name;
  final DateTime timestamp;
  final double paperclips;
  final double money;
  final GameMode gameMode;
  final bool isSyncedWithCloud;
  final String? cloudId;

  SaveGameInfo({
    required this.name,
    required this.timestamp,
    required this.paperclips,
    required this.money,
    required this.gameMode,
    this.isSyncedWithCloud = false,
    this.cloudId,
  });

  SaveGameInfo copyWith({
    String? name,
    DateTime? timestamp,
    double? paperclips,
    double? money,
    GameMode? gameMode,
    bool? isSyncedWithCloud,
    String? cloudId,
  }) {
    return SaveGameInfo(
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      paperclips: paperclips ?? this.paperclips,
      money: money ?? this.money,
      gameMode: gameMode ?? this.gameMode,
      isSyncedWithCloud: isSyncedWithCloud ?? this.isSyncedWithCloud,
      cloudId: cloudId ?? this.cloudId,
    );
  }
}