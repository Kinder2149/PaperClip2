import 'dart:convert';

/// Représente un instantané sérialisable de l'état du jeu.
///
/// La structure est organisée par grandes sections afin de rester
/// extensible et compatible avec les futures versions :
/// - metadata : informations de version, date, id de partie...
/// - core     : état coeur (joueur, progression, flags globaux)
/// - market   : état du marché (optionnel)
/// - production : état de la production (optionnel)
/// - stats    : statistiques cumulées (optionnel)
class GameSnapshot {
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> core;
  final Map<String, dynamic>? market;
  final Map<String, dynamic>? production;
  final Map<String, dynamic>? stats;

  const GameSnapshot({
    required this.metadata,
    required this.core,
    this.market,
    this.production,
    this.stats,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metadata': metadata,
      'core': core,
      if (market != null) 'market': market,
      if (production != null) 'production': production,
      if (stats != null) 'stats': stats,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final rawCore = json['core'];

    if (rawMetadata is! Map) {
      throw const FormatException('GameSnapshot.metadata doit être un objet Map');
    }
    if (rawCore is! Map) {
      throw const FormatException('GameSnapshot.core doit être un objet Map');
    }

    return GameSnapshot(
      metadata: Map<String, dynamic>.from(rawMetadata as Map),
      core: Map<String, dynamic>.from(rawCore as Map),
      market: json['market'] is Map
          ? Map<String, dynamic>.from(json['market'] as Map)
          : null,
      production: json['production'] is Map
          ? Map<String, dynamic>.from(json['production'] as Map)
          : null,
      stats: json['stats'] is Map
          ? Map<String, dynamic>.from(json['stats'] as Map)
          : null,
    );
  }

  factory GameSnapshot.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('GameSnapshot JSON doit être un objet racine');
    }
    return GameSnapshot.fromJson(Map<String, dynamic>.from(decoded as Map));
  }
}
