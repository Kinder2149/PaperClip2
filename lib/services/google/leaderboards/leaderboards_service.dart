import 'dart:collection';

import 'leaderboards_adapter.dart';
import 'leaderboards_mapper.dart';

/// Service Leaderboards (Étape 3)
/// - Best score uniquement: on ne soumet que si > dernier score soumis
/// - Anti-spam: intervalle minimum entre soumissions par leaderboard
/// - File d'attente locale si adapter non prêt / erreur transitoire
/// - Aucune dépendance au core gameplay ni à la sauvegarde
class LeaderboardsService {
  final LeaderboardsAdapter _adapter;
  final LeaderboardsMapper _mapper;

  final Map<String, int> _lastSubmitted = <String, int>{};
  final Map<String, DateTime> _lastSubmittedAt = <String, DateTime>{};
  final Queue<MapEntry<String, int>> _pending = Queue<MapEntry<String, int>>();

  /// Intervalle minimal entre deux soumissions du même leaderboard
  final Duration minSubmitInterval;

  LeaderboardsService({
    required LeaderboardsAdapter adapter,
    LeaderboardsMapper? mapper,
    this.minSubmitInterval = const Duration(seconds: 30),
  })  : _adapter = adapter,
        _mapper = mapper ?? LeaderboardsMapper();

  /// Consomme un événement normalisé (eventId + data) et tente une soumission.
  Future<void> handleEvent(String eventId, Map<String, dynamic> data) async {
    final pairs = _mapper.mapEvent(eventId, data);
    for (final p in pairs) {
      await _submitOrQueue(p.key, p.value);
    }
  }

  /// Soumission manuelle explicite (ex: score composite déjà calculé par orchestration)
  Future<void> submitExplicit(String leaderboardKey, int score) async {
    await _submitOrQueue(leaderboardKey, score);
  }

  /// Tente de soumettre les éléments en attente (à appeler quand l'identity devient prête).
  Future<void> tryFlush() async {
    final ready = await _adapter.isReady();
    if (!ready) return;

    while (_pending.isNotEmpty) {
      final entry = _pending.removeFirst();
      if (!_shouldSubmit(entry.key, entry.value)) {
        // Rien à faire si pas meilleur que dernier connu
        continue;
      }
      if (!_passesRateLimit(entry.key)) {
        // Trop tôt, replanifier en fin de file
        _pending.addLast(entry);
        break;
      }

      try {
        await _adapter.submitScore(entry.key, entry.value);
        _markSubmitted(entry.key, entry.value);
      } catch (_) {
        // En cas d'échec transitoire, on réinsère puis on sort
        _pending.addLast(entry);
        break;
      }
    }
  }

  bool _shouldSubmit(String key, int score) {
    final last = _lastSubmitted[key];
    if (last == null) return true;
    return score > last; // best score uniquement
  }

  bool _passesRateLimit(String key) {
    final lastAt = _lastSubmittedAt[key];
    if (lastAt == null) return true;
    return DateTime.now().difference(lastAt) >= minSubmitInterval;
  }

  void _markSubmitted(String key, int score) {
    _lastSubmitted[key] = score;
    _lastSubmittedAt[key] = DateTime.now();
  }

  Future<void> _submitOrQueue(String key, int score) async {
    // Best score uniquement
    if (!_shouldSubmit(key, score)) return;

    final ready = await _adapter.isReady();
    if (ready && _passesRateLimit(key)) {
      try {
        await _adapter.submitScore(key, score);
        _markSubmitted(key, score);
        return;
      } catch (_) {
        // chute en file d'attente
      }
    }
    // File d'attente locale (remplace une entrée plus faible du même leaderboard)
    // On supprime les entrées existantes pour la même key
    _pending.removeWhere((e) => e.key == key);
    _pending.addLast(MapEntry(key, score));
  }
}
