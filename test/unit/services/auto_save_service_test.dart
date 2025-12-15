import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/auto_save_service.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/constants/game_config.dart';

class _FakeOrchestrator implements AutoSaveOrchestratorPort {
  int autoSaveCalls = 0;
  String? lastAutoSaveReason;

  int backupCalls = 0;
  String? lastBackupName;
  String? lastBackupReason;

  int lifecycleCalls = 0;

  bool throwOnAutoSave = false;

  @override
  Future<void> requestAutoSave(GameState state, {String? reason}) async {
    autoSaveCalls++;
    lastAutoSaveReason = reason;
    if (throwOnAutoSave) {
      throw Exception('autosave failed');
    }
  }

  @override
  Future<void> requestBackup(
    GameState state, {
    required String backupName,
    String? reason,
    bool bypassCooldown = false,
  }) async {
    backupCalls++;
    lastBackupName = backupName;
    lastBackupReason = reason;
  }

  @override
  Future<void> requestLifecycleSave(GameState state, {String? reason}) async {
    lifecycleCalls++;
  }
}

class _FakeStorage implements AutoSaveStoragePort {
  List<SaveGameInfo> saves = <SaveGameInfo>[];
  final List<String> deleted = <String>[];

  @override
  Future<List<SaveGameInfo>> listSaves() async => saves;

  @override
  Future<void> deleteSaveByName(String name) async {
    deleted.add(name);
  }
}

class _RecordedEvent {
  final EventType type;
  final String title;
  final String? description;
  final EventImportance importance;

  const _RecordedEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.importance,
  });
}

class _FakeEvents implements AutoSaveEventPort {
  final List<_RecordedEvent> recorded = <_RecordedEvent>[];

  @override
  void addEvent(
    EventType type,
    String title, {
    required String description,
    required EventImportance importance,
  }) {
    recorded.add(
      _RecordedEvent(
        type: type,
        title: title,
        description: description,
        importance: importance,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoSaveService (P0)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets('start est idempotent: un seul timer actif', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('timer_idempotent');

      final orchestrator = _FakeOrchestrator();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.start();
      await service.start();

      await tester.pump(GameConstants.AUTO_SAVE_INTERVAL);
      expect(orchestrator.autoSaveCalls, 1);

      service.dispose();
      gameState.dispose();
    });

    testWidgets('stop annule les ticks autosave', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('timer_stop');

      final orchestrator = _FakeOrchestrator();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.start();
      service.stop();

      await tester.pump(GameConstants.AUTO_SAVE_INTERVAL);
      expect(orchestrator.autoSaveCalls, 0);

      service.dispose();
      gameState.dispose();
    });

    testWidgets('restart relance les ticks autosave après stop', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('timer_restart');

      final orchestrator = _FakeOrchestrator();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.start();
      service.stop();
      service.restart();

      await tester.pump(GameConstants.AUTO_SAVE_INTERVAL);
      expect(orchestrator.autoSaveCalls, 1);

      service.dispose();
      gameState.dispose();
    });

    test('performAutoSaveForTest ne fait rien si gameName est null', () async {
      final gameState = GameState();
      gameState.initialize();

      final orchestrator = _FakeOrchestrator();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.performAutoSaveForTest();

      expect(orchestrator.autoSaveCalls, 0);

      service.dispose();
      gameState.dispose();
    });

    test('performAutoSaveForTest déclenche requestAutoSave quand état OK', () async {
      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('autosave_ok');

      final orchestrator = _FakeOrchestrator();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.performAutoSaveForTest();

      expect(orchestrator.autoSaveCalls, 1);
      expect(orchestrator.lastAutoSaveReason, 'autosave_timer');
      expect(service.lastAutoSave, isNotNull);

      service.dispose();
      gameState.dispose();
    });

    test('performAutoSaveForTest n’appelle pas requestAutoSave si taille > max', () async {
      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('oversize');

      final orchestrator = _FakeOrchestrator();
      final events = _FakeEvents();
      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        events: events,
        postFrame: (VoidCallback cb) => cb(),
        maxStorageSizeBytes: 1,
      );

      await service.initialize();
      service.stop();

      await service.performAutoSaveForTest();

      expect(orchestrator.autoSaveCalls, 0);
      expect(service.lastAutoSave, isNull);

      service.dispose();
      gameState.dispose();
    });

    test('après N échecs, déclenche un backup + un event HIGH', () async {
      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('failures');

      final orchestrator = _FakeOrchestrator()..throwOnAutoSave = true;
      final storage = _FakeStorage();
      final events = _FakeEvents();

      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        storage: storage,
        events: events,
        postFrame: (VoidCallback cb) => cb(),
        maxFailedAttempts: 3,
      );

      await service.initialize();
      service.stop();

      await service.performAutoSaveForTest();
      await service.performAutoSaveForTest();
      await service.performAutoSaveForTest();

      expect(orchestrator.autoSaveCalls, 3);
      expect(orchestrator.backupCalls, 1);
      expect(orchestrator.lastBackupReason, 'autosave_service_create_backup');

      expect(events.recorded.length, 1);
      expect(events.recorded.first.importance, EventImportance.HIGH);

      service.dispose();
      gameState.dispose();
    });

    test('cleanupOldBackupsForTest supprime les backups au-delà de MAX_BACKUPS', () async {
      final gameState = GameState();
      gameState.initialize();
      await gameState.startNewGame('cleanup');

      final orchestrator = _FakeOrchestrator();
      final storage = _FakeStorage();

      storage.saves = <SaveGameInfo>[
        SaveGameInfo(
          id: 'b1',
          name: 'cleanup_backup_1',
          timestamp: DateTime(2025, 1, 1, 10, 0, 0),
          version: '1.0',
          gameMode: GameMode.INFINITE,
          isBackup: true,
        ),
        SaveGameInfo(
          id: 'b2',
          name: 'cleanup_backup_2',
          timestamp: DateTime(2025, 1, 1, 11, 0, 0),
          version: '1.0',
          gameMode: GameMode.INFINITE,
          isBackup: true,
        ),
        SaveGameInfo(
          id: 'b3',
          name: 'cleanup_backup_3',
          timestamp: DateTime(2025, 1, 1, 12, 0, 0),
          version: '1.0',
          gameMode: GameMode.INFINITE,
          isBackup: true,
        ),
        SaveGameInfo(
          id: 'b4',
          name: 'cleanup_backup_4',
          timestamp: DateTime(2025, 1, 1, 13, 0, 0),
          version: '1.0',
          gameMode: GameMode.INFINITE,
          isBackup: true,
        ),
      ];

      final service = AutoSaveService(
        gameState,
        orchestrator: orchestrator,
        storage: storage,
        postFrame: (VoidCallback cb) => cb(),
      );

      await service.cleanupOldBackupsForTest();

      expect(storage.deleted.length, 1);
      expect(storage.deleted.first, 'cleanup_backup_1');

      service.dispose();
      gameState.dispose();
    });
  });
}
