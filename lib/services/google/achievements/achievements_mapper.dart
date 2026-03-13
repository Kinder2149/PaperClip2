import 'achievements_keys.dart';

/// Mappe les événements locaux normalisés vers des clés de succès Google.
/// Aucun accès au gameplay ni persistance ici.
class AchievementsMapper {
  /// Retourne une liste de clés de succès à débloquer pour un événement donné.
  /// Les événements sont ceux décrits dans docs/progression/GAME_EVENTS_REFERENCE.md
  /// et mappés selon docs/google/ACHIEVEMENTS_MAPPING.md.
  List<String> mapEvent(String eventId, Map<String, dynamic> data) {
    final out = <String>[];
    switch (eventId) {
      case 'level.reached':
        final lvl = _asInt(data['level']);
        if (lvl != null && lvl >= 50) {
          out.add(AchievementKeys.expLevel50);
        }
        break;

      case 'production.total_clips':
        final total = _asInt(data['value']) ?? _asInt(data['total']) ?? _asInt(data['count']);
        if (total != null) {
          if (total >= 100000) out.add(AchievementKeys.totalClips100k);
          if (total >= 50000) out.add(AchievementKeys.totalClips50k);
          if (total >= 10000) out.add(AchievementKeys.totalClips10k);
        }
        break;

      case 'automation.autoclipper_purchased':
        final purchased = _asInt(data['count']) ?? 1;
        if (purchased >= 1) out.add(AchievementKeys.firstAutoclipper);
        break;

      case 'upgrades.branch_market_invested':
        final marketing = _asInt(data['marketing']) ?? 0;
        final reputation = _asInt(data['reputation']) ?? 0;
        final study = _asInt(data['study']) ?? _asInt(data['research']) ?? 0;
        final negotiation = _asInt(data['negotiation']) ?? 0;
        if (marketing > 0 && reputation > 0 && study > 0 && negotiation > 0) {
          out.add(AchievementKeys.marketEngineer);
        }
        break;

      case 'market.price_set':
      case 'market.demand_sampled':
        // L'orchestrateur peut envoyer un événement consolidé 'market.stable_demand'
        // avec { demand: 0.75, duration_seconds: 60 }
        final stable = data['stable_demand'] == true;
        final demand = _asDouble(data['demand']);
        final duration = _asInt(data['duration_seconds']);
        if (stable == true || (demand != null && demand >= 0.75 && (duration ?? 0) >= 60)) {
          out.add(AchievementKeys.marketSavvy);
        }
        break;

      case 'economy.net_profit':
        final net = _asInt(data['value']) ?? _asInt(data['net']) ?? _asInt(data['amount']);
        if (net != null && net >= 10000) out.add(AchievementKeys.banker10k);
        break;

      case 'upgrades.upgrade_purchased':
        // Efficacité: l'orchestrateur peut joindre des métriques dérivées
        final metalPerClip = _asDouble(data['metal_per_clip']);
        final efficiencyMaxed = data['efficiency_maxed'] == true;
        if ((metalPerClip != null && metalPerClip <= 0.05) || efficiencyMaxed) {
          out.add(AchievementKeys.efficiencyMaster);
        }
        break;

      case 'efficiency.updated':
        final efficiency = _asDouble(data['efficiency']);
        if (efficiency != null && efficiency >= 8.0) {
          out.add(AchievementKeys.efficiencyMaster);
        }
        break;

      case 'crisis.triggered':
        // Speed run = déclencher la crise en moins de 10 minutes
        final elapsed = _asInt(data['elapsed_seconds']);
        if (elapsed != null && elapsed <= 10 * 60) {
          out.add(AchievementKeys.speedrunLvl7Under20m);
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
