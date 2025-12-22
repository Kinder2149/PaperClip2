import 'dart:collection';

import '../../google/achievements/achievements_service.dart';
import '../../google/leaderboards/leaderboards_service.dart';
import '../../google/cloudsave/cloud_save_service.dart';
import '../../google/cloudsave/cloud_save_models.dart';
import 'backoff_policy.dart';
import 'sync_models.dart';
import 'sync_readiness_port.dart';

/// Orchestrateur de synchronisation (Étape 5)
/// - Coordonne Achievements / Leaderboards / Cloud Save
/// - Gère des files locales en mémoire (persistance hors-scope)
/// - Applique readiness + backoff + retry borné
/// - Ne contient aucune logique métier et n'écrit pas dans le core
class GoogleSyncOrchestrator {
  final AchievementsService _achievements;
  final LeaderboardsService _leaderboards;
  final CloudSaveService _cloud;
  final SyncReadinessPort _readiness;

  final Queue<SyncQueueItem> _queueAchievements = Queue();
  final Queue<SyncQueueItem> _queueLeaderboards = Queue();
  final Queue<SyncQueueItem> _queueCloud = Queue();

  GoogleSyncOrchestrator({
    required AchievementsService achievements,
    required LeaderboardsService leaderboards,
    required CloudSaveService cloud,
    required SyncReadinessPort readiness,
  })  : _achievements = achievements,
        _leaderboards = leaderboards,
        _cloud = cloud,
        _readiness = readiness;

  // Enqueue API (événements déjà normalisés: eventId + payload)
  void enqueueAchievementEvent({
    required String eventId,
    required Map<String, dynamic> payload,
  }) {
    _queueAchievements.add(SyncQueueItem(
      id: _uuid(),
      type: 'achievement',
      createdAt: DateTime.now(),
      payload: {
        'eventId': eventId,
        'payload': Map<String, dynamic>.from(payload),
      },
    ));
  }

  void enqueueLeaderboardEvent({
    required String eventId,
    required Map<String, dynamic> payload,
  }) {
    _queueLeaderboards.add(SyncQueueItem(
      id: _uuid(),
      type: 'leaderboard',
      createdAt: DateTime.now(),
      payload: {
        'eventId': eventId,
        'payload': Map<String, dynamic>.from(payload),
      },
    ));
  }

  void enqueueCloudPush({
    required CloudSaveRecord record,
  }) {
    _queueCloud.add(SyncQueueItem(
      id: _uuid(),
      type: 'cloudsave',
      createdAt: DateTime.now(),
      payload: {
        'record': record.toJson(),
      },
    ));
  }

  /// Traitement manuel (appelé par l'UI ou périodiquement par le runtime)
  Future<void> processQueues() async {
    final allowed = await _readiness.isSyncAllowed();
    final online = await _readiness.hasNetwork();
    if (!allowed || !online) {
      return; // opt-in strict + connectivité requise
    }

    await _drainAchievements();
    await _drainLeaderboards();
    await _drainCloud();
  }

  Future<void> _drainAchievements() async {
    // Achievements: handleEvent + tryFlush
    int cycles = 0; // empêche boucles infinies si réinsertion
    while (_queueAchievements.isNotEmpty && cycles < 1000) {
      cycles++;
      final item = _queueAchievements.removeFirst();
      if (!_due(item)) {
        _queueAchievements.addLast(item);
        break;
      }
      try {
        final eventId = item.payload['eventId'] as String;
        final payload = (item.payload['payload'] as Map).cast<String, dynamic>();
        await _achievements.handleEvent(eventId, payload);
        await _achievements.tryFlush();
        // Succès: on ne réinsère pas
      } catch (e) {
        _scheduleRetry(item);
        _queueAchievements.addLast(item);
        break; // on laisse respirer
      }
    }
  }

  Future<void> _drainLeaderboards() async {
    int cycles = 0;
    while (_queueLeaderboards.isNotEmpty && cycles < 1000) {
      cycles++;
      final item = _queueLeaderboards.removeFirst();
      if (!_due(item)) {
        _queueLeaderboards.addLast(item);
        break;
      }
      try {
        final eventId = item.payload['eventId'] as String;
        final payload = (item.payload['payload'] as Map).cast<String, dynamic>();
        await _leaderboards.handleEvent(eventId, payload);
        await _leaderboards.tryFlush();
      } catch (e) {
        _scheduleRetry(item);
        _queueLeaderboards.addLast(item);
        break;
      }
    }
  }

  Future<void> _drainCloud() async {
    int cycles = 0;
    while (_queueCloud.isNotEmpty && cycles < 1000) {
      cycles++;
      final item = _queueCloud.removeFirst();
      if (!_due(item)) {
        _queueCloud.addLast(item);
        break;
      }
      try {
        final recordJson = (item.payload['record'] as Map).cast<String, dynamic>();
        final record = CloudSaveRecord.fromJson(recordJson);
        await _cloud.upload(record);
      } catch (e) {
        _scheduleRetry(item);
        _queueCloud.addLast(item);
        break;
      }
    }
  }

  bool _due(SyncQueueItem item) {
    if (item.nextAttemptAt == null) return true;
    return DateTime.now().isAfter(item.nextAttemptAt!);
  }

  void _scheduleRetry(SyncQueueItem item) {
    item.attempts += 1;
    item.nextAttemptAt = DateTime.now().add(BackoffPolicy.nextDelay(item.attempts));
  }

  String _uuid() {
    // UUID simplifié (non cryptographique)
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'q$now-${_rand4()}${_rand4()}';
  }

  String _rand4() {
    final v = (DateTime.now().microsecondsSinceEpoch % 65536).toRadixString(16);
    return v.padLeft(4, '0');
  }
}
