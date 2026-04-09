// test/unit/enterprise_creation_test.dart
// CHANTIER-01: Tests unitaires création entreprise

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  group('CHANTIER-01: Enterprise Creation', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    test('createNewEnterprise génère un UUID v4 valide', () async {
      await gameState.createNewEnterprise('Test Corp');

      expect(gameState.enterpriseId, isNotNull);
      expect(gameState.enterpriseId, isNotEmpty);
      
      // Vérifier format UUID v4
      final uuidV4Pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
      );
      expect(uuidV4Pattern.hasMatch(gameState.enterpriseId!), isTrue);
    });

    test('createNewEnterprise définit le nom correctement', () async {
      const testName = 'PaperClip Industries';
      await gameState.createNewEnterprise(testName);

      expect(gameState.enterpriseName, equals(testName));
    });

    test('createNewEnterprise définit la date de création', () async {
      final beforeCreation = DateTime.now();
      await gameState.createNewEnterprise('Test Corp');
      final afterCreation = DateTime.now();

      expect(gameState.enterpriseCreatedAt, isNotNull);
      expect(
        gameState.enterpriseCreatedAt!.isAfter(beforeCreation.subtract(const Duration(seconds: 1))),
        isTrue
      );
      expect(
        gameState.enterpriseCreatedAt!.isBefore(afterCreation.add(const Duration(seconds: 1))),
        isTrue
      );
    });

    test('createNewEnterprise initialise les ressources rares à 0', () async {
      await gameState.createNewEnterprise('Test Corp');

      expect(gameState.quantum, equals(0));
      expect(gameState.pointsInnovation, equals(0));
      expect(gameState.totalResets, equals(0));
    });

    test('createNewEnterprise initialise le GameState correctement', () async {
      await gameState.createNewEnterprise('Test Corp');

      // GameMode supprimé lors de CHANTIER-01
      expect(gameState.playerManager, isNotNull);
      expect(gameState.resourceManager, isNotNull);
      expect(gameState.marketManager, isNotNull);
    });

    test('setEnterpriseId accepte un UUID v4 valide', () {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';
      gameState.setEnterpriseId(validUuid);

      expect(gameState.enterpriseId, equals(validUuid));
    });

    test('setEnterpriseName définit le nom', () {
      const testName = 'New Enterprise Name';
      gameState.setEnterpriseName(testName);

      expect(gameState.enterpriseName, equals(testName));
    });

    test('addQuantum augmente le quantum', () {
      gameState.addQuantum(10);
      expect(gameState.quantum, equals(10));

      gameState.addQuantum(5);
      expect(gameState.quantum, equals(15));
    });

    test('spendQuantum diminue le quantum', () {
      gameState.addQuantum(20);
      final success = gameState.spendQuantum(8);

      expect(success, isTrue);
      expect(gameState.quantum, equals(12));
    });

    test('spendQuantum échoue si quantum insuffisant', () {
      gameState.addQuantum(5);
      final success = gameState.spendQuantum(10);

      expect(success, isFalse);
      expect(gameState.quantum, equals(5));
    });

    test('addPointsInnovation augmente les points', () {
      gameState.addPointsInnovation(100);
      expect(gameState.pointsInnovation, equals(100));

      gameState.addPointsInnovation(50);
      expect(gameState.pointsInnovation, equals(150));
    });

    test('spendPointsInnovation diminue les points', () {
      gameState.addPointsInnovation(200);
      final success = gameState.spendPointsInnovation(75);

      expect(success, isTrue);
      expect(gameState.pointsInnovation, equals(125));
    });

    test('spendPointsInnovation échoue si points insuffisants', () {
      gameState.addPointsInnovation(50);
      final success = gameState.spendPointsInnovation(100);

      expect(success, isFalse);
      expect(gameState.pointsInnovation, equals(50));
    });

    test('deleteEnterprise réinitialise les champs entreprise', () async {
      await gameState.createNewEnterprise('Test Corp');
      gameState.addQuantum(10);
      gameState.addPointsInnovation(100);

      await gameState.deleteEnterprise();

      expect(gameState.enterpriseId, isNull);
      expect(gameState.enterpriseName, equals('Mon Entreprise')); // Valeur par défaut
      expect(gameState.enterpriseCreatedAt, isNull);
      expect(gameState.quantum, equals(0));
      expect(gameState.pointsInnovation, equals(0));
    });

    test('Deux entreprises ont des IDs différents', () async {
      final state1 = GameState();
      final state2 = GameState();

      await state1.createNewEnterprise('Corp 1');
      await state2.createNewEnterprise('Corp 2');

      expect(state1.enterpriseId, isNot(equals(state2.enterpriseId)));
    });
  });
}
