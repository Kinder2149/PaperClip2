// lib/core/constants/imports.dart
export 'dart:math' show pow, min, max;
export 'dart:async';
export 'dart:io';

// Entités
export 'package:paperclip2/domain/entities/player_entity.dart';
export 'package:paperclip2/domain/entities/market_entity.dart';
export 'package:paperclip2/domain/entities/game_state_entity.dart';
export 'package:paperclip2/domain/entities/level_system_entity.dart';
export 'package:paperclip2/domain/entities/statistics_entity.dart';
export 'package:paperclip2/domain/entities/upgrade_entity.dart';
export 'package:paperclip2/domain/entities/save_game_info.dart';
export 'package:paperclip2/domain/entities/sale_record_entity.dart';

// Enums
export 'enums.dart';

// Extensions des plateformes
export 'package:flutter/foundation.dart' show kDebugMode;
export 'package:flutter/services.dart';

// Constantes
export 'game_constants.dart';

// Types alias
typedef Player = PlayerEntity;
typedef Market = MarketEntity;
typedef GameState = GameStateEntity;
typedef LevelSystem = LevelSystemEntity;
typedef Statistics = StatisticsEntity;
typedef Upgrade = UpgradeEntity;
typedef SaleRecord = SaleRecordEntity;