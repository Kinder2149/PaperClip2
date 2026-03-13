import 'dart:collection';

import 'achievements_adapter.dart';
import 'achievements_mapper.dart';
import 'achievements_keys.dart';

/// Service Achievements (Étape 2)
/// - Reçoit des événements locaux normalisés (eventId + data)
/// - Mappe vers des clés de succès Google
/// - Déclenche l'unlock via l'adapter si prêt, sinon met en file d'attente
/// - Aucune dépendance au core gameplay ni à la sauvegarde
class AchievementsService {
  final AchievementsAdapter _adapter;
  final AchievementsMapper _mapper;

  final Queue<String> _pending = Queue<String>();
  final Set<String> _submittedThisSession = <String>{};
  int _lastLevelReported = 0; // progression locale pour succès progressifs

  AchievementsService({
    required AchievementsAdapter adapter,
    AchievementsMapper? mapper,
  })  : _adapter = adapter,
        _mapper = mapper ?? AchievementsMapper();

  /// Point d'entrée unique pour consommer un événement local documenté.
  Future<void> handleEvent(String eventId, Map<String, dynamic> data) async {
    // Gestion dédiée de la réussite progressive "Gain d'exp": 50 étapes, 1 par niveau atteint
    if (eventId == 'level.reached') {
      final lvl = _asInt(data['level']) ?? 0;
      final cappedNew = lvl.clamp(0, 50);
      final cappedPrev = _lastLevelReported.clamp(0, 50);
      final delta = cappedNew - cappedPrev;
      if (delta > 0) {
        try {
          if (await _adapter.isReady()) {
            await _adapter.increment(AchievementKeys.expLevel50, delta);
          }
          _lastLevelReported = lvl;
        } catch (_) {}
      }
    }

    final keys = _mapper.mapEvent(eventId, data);
    for (final k in keys) {
      await _submitOrQueue(k);
    }
  }

  /// Tente de soumettre les clés en attente (à appeler quand l'identity devient prête).
  Future<void> tryFlush() async {
    final ready = await _adapter.isReady();
    if (!ready) return;

    while (_pending.isNotEmpty) {
      final key = _pending.removeFirst();
      if (_submittedThisSession.contains(key)) continue; // déduplication session
      try {
        await _adapter.unlock(key);
        _submittedThisSession.add(key);
      } catch (_) {
        // En cas d'échec transitoire, on réinsère en fin de file et on arrête
        _pending.addLast(key);
        break;
      }
    }
  }

  Future<void> _submitOrQueue(String key) async {
    if (_submittedThisSession.contains(key)) return;

    final ready = await _adapter.isReady();
    if (ready) {
      try {
        await _adapter.unlock(key);
        _submittedThisSession.add(key);
        return;
      } catch (_) {
        // Tomber en file d'attente en cas d'échec
      }
    }
    // File d'attente locale (sans doublon)
    if (!_pending.contains(key)) {
      _pending.addLast(key);
    }
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
