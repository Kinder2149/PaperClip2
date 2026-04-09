// test/unit/enterprise_persistence_test.dart
// CHANTIER-01: Tests persistence entreprise

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_mapper.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/constants/game_config.dart';

void main() {
  group('CHANTIER-01: Enterprise Persistence', () {
    late GameState gameState;

    setUp(() async {
      gameState = GameState();
      await gameState.createNewEnterprise('Test Enterprise');
    });

    test('toSnapshotV3 génère un snapshot version 3', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['version'], equals(3));
    });

    test('toSnapshotV3 inclut enterpriseId', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['enterpriseId'], equals(gameState.enterpriseId));
      expect(snapshot.metadata['enterpriseId'], isNotNull);
    });

    test('toSnapshotV3 inclut enterpriseName', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['enterpriseName'], equals('Test Enterprise'));
    });

    test('toSnapshotV3 inclut createdAt', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['createdAt'], isNotNull);
      expect(snapshot.metadata['createdAt'], isA<String>());
    });

    test('toSnapshotV3 inclut gameMode', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['gameMode'], equals('INFINITE'));
    });

    test('toSnapshotV3 inclut ressources rares', () {
      gameState.addQuantum(15);
      gameState.addPointsInnovation(250);

      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.metadata['quantum'], equals(15));
      expect(snapshot.metadata['pointsInnovation'], equals(250));
      expect(snapshot.metadata['totalResets'], equals(0));
    });

    test('toSnapshotV3 inclut structures agents vides', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.core['agents'], isNotNull);
      expect(snapshot.core['agents'], isA<Map<String, dynamic>>());
      expect(snapshot.core['agents']['unlocked'], equals([]));
      expect(snapshot.core['agents']['active'], equals([]));
    });

    test('toSnapshotV3 inclut structures research vides', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.core['research'], isNotNull);
      expect(snapshot.core['research'], isA<Map<String, dynamic>>());
      expect(snapshot.core['research']['completed'], equals([]));
      expect(snapshot.core['research']['available'], equals([]));
    });

    test('toSnapshotV3 inclut données core', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.core['player'], isNotNull);
      expect(snapshot.core['levelSystem'], isNotNull);
      expect(snapshot.core['missionSystem'], isNotNull);
    });

    test('toSnapshotV3 inclut market, production, stats', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      expect(snapshot.market, isNotNull);
      expect(snapshot.production, isNotNull);
      expect(snapshot.stats, isNotNull);
    });

    test('fromSnapshotV3 restaure enterpriseId', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final originalId = gameState.enterpriseId;

      final newState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newState, snapshot);

      expect(newState.enterpriseId, equals(originalId));
    });

    test('fromSnapshotV3 restaure enterpriseName', () {
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);

      final newState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newState, snapshot);

      expect(newState.enterpriseName, equals('Test Enterprise'));
    });

    test('fromSnapshotV3 restaure ressources rares', () {
      gameState.addQuantum(42);
      gameState.addPointsInnovation(777);

      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final newState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newState, snapshot);

      expect(newState.quantum, equals(42));
      expect(newState.pointsInnovation, equals(777));
    });

    test('Cycle complet save/load préserve les données', () {
      gameState.addQuantum(25);
      gameState.addPointsInnovation(500);

      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final restoredState = GameState();
      GamePersistenceMapper.fromSnapshotV3(restoredState, snapshot);

      expect(restoredState.enterpriseId, equals(gameState.enterpriseId));
      expect(restoredState.enterpriseName, equals(gameState.enterpriseName));
      expect(restoredState.quantum, equals(25));
      expect(restoredState.pointsInnovation, equals(500));
    });

    test('toSnapshotV3 génère lastModified récent', () {
      final before = DateTime.now();
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final after = DateTime.now();

      expect(snapshot.metadata['lastModified'], isNotNull);
      final lastModified = DateTime.parse(snapshot.metadata['lastModified'] as String);
      
      expect(lastModified.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(lastModified.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
