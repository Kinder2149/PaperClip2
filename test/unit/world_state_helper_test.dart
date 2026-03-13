import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/widgets/worlds/world_state_helper.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/constants/game_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorldStateHelper', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('canonicalStateFor', () {
      test('retourne cloud_synced pour entrée cloud avec in_sync', () async {
        final entry = SaveEntry(
          source: SaveSource.cloud,
          id: 'world-1',
          name: 'World 1',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: 'player-123',
          cloudSyncState: 'in_sync',
          remoteVersion: 1,
          canLoad: true,
        );

        final state = await WorldStateHelper.canonicalStateFor(entry);
        expect(state, 'cloud_synced', reason: 'Entrée cloud avec in_sync devrait être cloud_synced');
      });

      test('retourne cloud_pending pour entrée avec ahead_local', () async {
        final entry = SaveEntry(
          source: SaveSource.local,
          id: 'world-2',
          name: 'World 2',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: 'player-123',
          cloudSyncState: 'ahead_local',
          remoteVersion: 1,
          canLoad: true,
        );

        final state = await WorldStateHelper.canonicalStateFor(entry);
        expect(state, 'cloud_pending');
      });

      test('retourne cloud_error pour entrée avec ahead_remote', () async {
        final entry = SaveEntry(
          source: SaveSource.local,
          id: 'world-3',
          name: 'World 3',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: 'player-123',
          cloudSyncState: 'ahead_remote',
          remoteVersion: 2,
          canLoad: true,
        );

        final state = await WorldStateHelper.canonicalStateFor(entry);
        expect(state, 'cloud_error');
      });

      test('retourne cloud_synced pour entrée locale sans cloud (comportement par défaut)', () async {
        final entry = SaveEntry(
          source: SaveSource.local,
          id: 'world-4',
          name: 'World 4',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: null,
          cloudSyncState: null,
          remoteVersion: null,
          canLoad: true,
        );

        final state = await WorldStateHelper.canonicalStateFor(entry);
        // mapCloudStatus(null) retourne 'in_sync' par défaut
        // Donc canonicalStateFor retourne 'cloud_synced'
        expect(state, 'cloud_synced', reason: 'Par défaut, sans info cloud, considéré comme cloud_synced');
      });
    });

    group('canonicalLabel', () {
      test('retourne libellé correct pour cloud_synced', () {
        expect(WorldStateHelper.canonicalLabel('cloud_synced'), 'À jour');
      });

      test('retourne libellé correct pour cloud_pending', () {
        expect(WorldStateHelper.canonicalLabel('cloud_pending'), 'À synchroniser');
      });

      test('retourne libellé correct pour cloud_error', () {
        expect(WorldStateHelper.canonicalLabel('cloud_error'), 'Erreur cloud');
      });

      test('retourne libellé correct pour local_only', () {
        expect(WorldStateHelper.canonicalLabel('local_only'), 'Local uniquement');
      });

      test('retourne libellé par défaut pour état inconnu', () {
        expect(WorldStateHelper.canonicalLabel('unknown'), 'Local uniquement');
      });
    });

    group('mapCloudStatus', () {
      test('retourne in_sync pour in_sync', () {
        expect(WorldStateHelper.mapCloudStatus('in_sync'), 'in_sync');
      });

      test('retourne ahead_local pour ahead_local', () {
        expect(WorldStateHelper.mapCloudStatus('ahead_local'), 'ahead_local');
      });

      test('retourne ahead_remote pour ahead_remote', () {
        expect(WorldStateHelper.mapCloudStatus('ahead_remote'), 'ahead_remote');
      });

      test('retourne in_sync par défaut pour null', () {
        expect(WorldStateHelper.mapCloudStatus(null), 'in_sync', reason: 'Par défaut, retourne in_sync pour éviter faux positifs');
      });

      test('retourne in_sync par défaut pour chaîne vide', () {
        expect(WorldStateHelper.mapCloudStatus(''), 'in_sync', reason: 'Par défaut, retourne in_sync pour éviter faux positifs');
      });

      test('retourne in_sync pour unknown', () {
        expect(WorldStateHelper.mapCloudStatus('unknown'), 'in_sync', reason: 'unknown est considéré comme présent et non bloquant');
      });
    });

    group('hasCloudPresenceSync', () {
      test('retourne true pour entrée cloud', () {
        final entry = SaveEntry(
          source: SaveSource.cloud,
          id: 'world-5',
          name: 'World 5',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: 'player-123',
          cloudSyncState: 'in_sync',
          canLoad: true,
        );

        expect(WorldStateHelper.hasCloudPresenceSync(entry), true);
      });

      test('retourne true pour entrée locale avec playerId', () {
        final entry = SaveEntry(
          source: SaveSource.local,
          id: 'world-6',
          name: 'World 6',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: 'player-123',
          cloudSyncState: 'ahead_local',
          canLoad: true,
        );

        expect(WorldStateHelper.hasCloudPresenceSync(entry), true);
      });

      test('retourne false pour entrée locale sans playerId', () {
        final entry = SaveEntry(
          source: SaveSource.local,
          id: 'world-7',
          name: 'World 7',
          lastModified: DateTime.now(),
          gameMode: GameMode.INFINITE,
          version: GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          playerId: null,
          cloudSyncState: null,
          canLoad: true,
        );

        expect(WorldStateHelper.hasCloudPresenceSync(entry), false);
      });
    });
  });
}
