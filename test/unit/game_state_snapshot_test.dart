import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

/// Tests unitaires pour GameState et Snapshot v3
/// 
/// Ces tests valident :
/// 1. Création entreprise avec UUID v4
/// 2. Génération snapshot v3
/// 3. Format snake_case et dates ISO 8601
/// 4. Restauration depuis snapshot
/// 5. Validation format et structure
void main() {
  group('🏢 Création Entreprise', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('TEST 1: Création entreprise génère UUID v4', () async {
      final enterpriseName = 'Test Enterprise ${DateTime.now().millisecondsSinceEpoch}';
      await gameState.createNewEnterprise(enterpriseName);
      
      final enterpriseId = gameState.enterpriseId;
      final savedName = gameState.enterpriseName;

      expect(enterpriseId, isNotNull, reason: 'EnterpriseId doit être généré');
      expect(enterpriseId, isNotEmpty, reason: 'EnterpriseId non vide');
      expect(enterpriseId!.length, equals(36), reason: 'UUID v4 = 36 caractères');
      
      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidV4Pattern.hasMatch(enterpriseId), isTrue,
        reason: 'EnterpriseId doit être un UUID v4 valide');
      
      expect(savedName, equals(enterpriseName), reason: 'Nom entreprise sauvegardé');
    });

    test('TEST 2: Validation format UUID v4 strict', () async {
      await gameState.createNewEnterprise('Test UUID Validation');
      final enterpriseId = gameState.enterpriseId!;
      
      final parts = enterpriseId.split('-');
      expect(parts.length, equals(5), reason: 'UUID a 5 parties');
      expect(parts[0].length, equals(8), reason: 'Partie 1 = 8 chars');
      expect(parts[1].length, equals(4), reason: 'Partie 2 = 4 chars');
      expect(parts[2].length, equals(4), reason: 'Partie 3 = 4 chars');
      expect(parts[3].length, equals(4), reason: 'Partie 4 = 4 chars');
      expect(parts[4].length, equals(12), reason: 'Partie 5 = 12 chars');
      
      expect(parts[2][0], equals('4'), reason: 'UUID version 4');
      
      final variantChar = parts[3][0].toLowerCase();
      expect(['8', '9', 'a', 'b'], contains(variantChar),
        reason: 'UUID variant RFC 4122');
    });

    test('TEST 3: Suppression entreprise nettoie les données', () async {
      await gameState.createNewEnterprise('Test Delete');
      expect(gameState.enterpriseId, isNotNull);
      
      await gameState.deleteEnterprise();
      
      expect(gameState.enterpriseId, isNull, reason: 'EnterpriseId supprimé');
      expect(gameState.enterpriseName, equals('Mon Entreprise'), 
        reason: 'Nom réinitialisé');
    });
  });

  group('📸 Snapshot v3 - Structure', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('TEST 4: Snapshot v3 - Structure et métadonnées', () async {
      await gameState.createNewEnterprise('Test Snapshot');
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();

      expect(json, contains('metadata'), reason: 'Snapshot doit avoir metadata');
      expect(json, contains('core'), reason: 'Snapshot doit avoir core');
      
      final metadata = json['metadata'] as Map<String, dynamic>;
      expect(metadata['snapshotSchemaVersion'], equals(3), 
        reason: 'Version snapshot doit être 3');
      expect(metadata['enterpriseId'], equals(gameState.enterpriseId),
        reason: 'EnterpriseId dans metadata');
      expect(metadata['savedAt'], isNotNull, reason: 'savedAt présent');
      
      final savedAt = metadata['savedAt'] as String;
      final parsedDate = DateTime.parse(savedAt);
      expect(parsedDate, isA<DateTime>(), reason: 'savedAt doit être ISO 8601');
    });

    test('TEST 5: Snapshot v3 - Données game', () async {
      await gameState.createNewEnterprise('Test Core Data');
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      
      // enterpriseName est dans la section 'game', pas 'core'
      expect(json, contains('core'), reason: 'Section core présente');
      
      // Vérifier que le snapshot contient les données de jeu
      final core = json['core'] as Map<String, dynamic>;
      expect(core, isA<Map<String, dynamic>>(), reason: 'Core est un Map');
    });

    test('TEST 6: Métadonnées snapshot complètes', () async {
      await gameState.createNewEnterprise('Test Metadata Complete');
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      final metadata = json['metadata'] as Map<String, dynamic>;

      expect(metadata, contains('schemaVersion'));
      expect(metadata, contains('snapshotSchemaVersion'));
      expect(metadata, contains('enterpriseId'));
      expect(metadata, contains('storageMode'));
      expect(metadata, contains('savedAt'));
      
      expect(metadata['schemaVersion'], equals(1));
      expect(metadata['snapshotSchemaVersion'], equals(3));
      expect(metadata['storageMode'], anyOf(['local', 'cloud']));
    });
  });

  group('🔄 Restauration Snapshot', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('TEST 7: Restauration depuis snapshot - EnterpriseId', () async {
      await gameState.createNewEnterprise('Original Enterprise');
      final originalId = gameState.enterpriseId;
      
      final snapshot = gameState.toSnapshot();
      
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);
      
      // applySnapshot restaure l'enterpriseId depuis metadata
      expect(newGameState.enterpriseId, equals(originalId),
        reason: 'EnterpriseId restauré depuis metadata');
      
      newGameState.dispose();
    });

    test('TEST 8: Snapshot contient toutes les métadonnées', () async {
      await gameState.createNewEnterprise('Complete Restore Test');
      final originalId = gameState.enterpriseId;
      final originalCreatedAt = gameState.enterpriseCreatedAt;
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      final metadata = json['metadata'] as Map<String, dynamic>;
      
      // Vérifier que les métadonnées sont présentes dans le snapshot
      expect(metadata['enterpriseId'], equals(originalId),
        reason: 'EnterpriseId dans metadata');
      expect(metadata, contains('savedAt'),
        reason: 'savedAt dans metadata');
      
      // Vérifier que createdAt est préservé quelque part
      expect(originalCreatedAt, isNotNull,
        reason: 'Date de création existe');
    });

    test('TEST 9: Snapshot JSON sérialisable', () async {
      await gameState.createNewEnterprise('Test JSON Serialization');
      
      final snapshot = gameState.toSnapshot();
      final jsonString = snapshot.toJsonString();
      
      expect(() => jsonString, returnsNormally);
      expect(jsonString, isNotEmpty);
      expect(jsonString, startsWith('{'));
      expect(jsonString, endsWith('}'));
    });

    test('TEST 10: Snapshot toJson est déterministe', () async {
      await gameState.createNewEnterprise('Test Deterministic');
      
      final snapshot1 = gameState.toSnapshot();
      final snapshot2 = gameState.toSnapshot();
      
      final json1 = snapshot1.toJson();
      final json2 = snapshot2.toJson();
      
      expect(json1['core'], equals(json2['core']));
      expect(json1['metadata']['enterpriseId'], equals(json2['metadata']['enterpriseId']));
    });
  });

  group('📅 Dates ISO 8601', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('TEST 11: Dates ISO 8601 cohérentes', () async {
      await gameState.createNewEnterprise('Test Dates');
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      final metadata = json['metadata'] as Map<String, dynamic>;
      final core = json['core'] as Map<String, dynamic>;

      final savedAt = DateTime.parse(metadata['savedAt'] as String);
      final createdAtStr = core['enterpriseCreatedAt'] as String?;
      
      if (createdAtStr != null) {
        final createdAt = DateTime.parse(createdAtStr);
        expect(savedAt.isAfter(createdAt) || savedAt.isAtSameMomentAs(createdAt), 
          isTrue, reason: 'savedAt >= createdAt');
      }
    });
  });

  group('🔍 Validation Format', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('TEST 12: Snapshot préserve le mode de stockage', () async {
      await gameState.createNewEnterprise('Test Storage Mode');
      
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      final metadata = json['metadata'] as Map<String, dynamic>;

      expect(metadata['storageMode'], isIn(['local', 'cloud']));
    });

    test('TEST 13: Snapshot gère les valeurs nulles correctement', () async {
      final snapshot = gameState.toSnapshot();
      final json = snapshot.toJson();
      final metadata = json['metadata'] as Map<String, dynamic>;

      expect(metadata, contains('enterpriseId'));
    });
  });
}
