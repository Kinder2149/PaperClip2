import 'leaderboards_keys.dart';

/// Mappe des événements normalisés vers (leaderboardKey, score).
/// - Ne calcule pas de score composite: il doit être fourni en entrée si nécessaire.
class LeaderboardsMapper {
  /// Retourne des paires (key, score) à partir d'un event normalisé.
  /// Event attendu: eventId + payload, cf. GAME_EVENTS_REFERENCE.md et LEADERBOARDS_MAPPING.md
  List<MapEntry<String, int>> mapEvent(String eventId, Map<String, dynamic> data) {
    final out = <MapEntry<String, int>>[];
    switch (eventId) {
      case 'production.total_clips':
        final v = _asInt(data['value']) ?? _asInt(data['total']) ?? _asInt(data['count']);
        if (v != null) out.add(MapEntry(LeaderboardsKeys.productionTotalClips, v));
        break;
      case 'economy.net_profit':
        final d = _asDouble(data['value']) ?? _asDouble(data['net']) ?? _asDouble(data['amount']);
        if (d != null) {
          final scaled = (d * 10000).round(); // 4 décimales
          out.add(MapEntry(LeaderboardsKeys.netProfit, scaled));
        }
        break;
      case 'leaderboard.general_score':
        // Si une couche orchestratrice fournit un score composite explicite
        final d = _asDouble(data['score']);
        if (d != null) {
          final scaled = (d * 100).round(); // 2 décimales
          out.add(MapEntry(LeaderboardsKeys.general, scaled));
        }
        break;
      default:
        break;
    }
    return out;
  }

  int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _asDouble(Object? v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
