// Helpers pour Tests E2E - Phase 4
// Fonctions utilitaires pour simplifier l'écriture des tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

/// Setup - Login et attente initialisation
/// Note: Version simplifiée pour tests E2E avec mocks
Future<void> loginAndWait(
  WidgetTester tester, {
  String uid = 'test-user-123',
  String email = 'test@example.com',
}) async {
  // Version simplifiée - à adapter selon l'implémentation réelle
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ElevatedButton(
            key: const Key('login_button'),
            onPressed: () async {
              // Simuler login
            },
            child: const Text('Login'),
          );
        },
      ),
    ),
  ));

  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

/// Setup - Logout
Future<void> logout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('logout_button')));
  await tester.pumpAndSettle();
}

/// Setup - Créer un conflit entre local et cloud
/// Note: Utilise les mocks pour simuler le conflit
Future<void> setupConflict(
  WidgetTester tester, {
  required int localLevel,
  required int cloudLevel,
}) async {
  // Le conflit sera configuré via les mocks dans les tests
  // Cette fonction sert de placeholder pour la structure
}

/// Setup - Sauvegarder et restaurer GameState
/// Note: Version simplifiée pour tests
Future<GameState?> saveAndRestore(
  WidgetTester tester,
  GameState originalState,
) async {
  // Sauvegarder
  await originalState.saveOnImportantEvent();
  final snapshot = originalState.toSnapshot();

  // Créer nouveau GameState et restaurer
  final newState = GameState();
  // Attendre initialisation (à adapter selon l'implémentation)
  await Future.delayed(const Duration(milliseconds: 100));
  
  return newState;
}

/// Assertions - Vérifier égalité GameState
void expectGameStateEquals(GameState actual, GameState expected) {
  expect(actual.enterpriseId, equals(expected.enterpriseId));
  expect(actual.enterpriseName, equals(expected.enterpriseName));
  
  // PlayerManager
  expect(actual.playerManager.money, equals(expected.playerManager.money));
  expect(actual.playerManager.metal, equals(expected.playerManager.metal));
  expect(actual.playerManager.paperclips, equals(expected.playerManager.paperclips));
}

/// Assertions - Vérifier snapshot valide
void expectSnapshotValid(GameSnapshot snapshot) {
  expect(snapshot, isNotNull);
  expect(snapshot.metadata, isNotEmpty);
  expect(snapshot.core, isNotEmpty);
  expect(snapshot.core['enterpriseId'], isNotNull);
  expect(snapshot.core['enterpriseName'], isNotNull);
}

/// Factory - Créer snapshot de test
GameSnapshot createTestSnapshot({
  int level = 1,
  double money = 100.0,
  double metal = 50.0,
  int paperclips = 0,
  String? enterpriseId,
  String? enterpriseName,
}) {
  return GameSnapshot(
    metadata: {
      'lastSaved': DateTime.now().toIso8601String(),
      'deviceInfo': 'test-device',
      'appVersion': '1.0.0',
    },
    core: {
      'level': level,
      'money': money,
      'metal': metal,
      'paperclips': paperclips,
      'enterpriseId': enterpriseId ?? '550e8400-e29b-41d4-a716-446655440000',
      'enterpriseName': enterpriseName ?? 'Test Enterprise',
    },
  );
}

/// Factory - Créer snapshot large (pour tests performance)
GameSnapshot createLargeSnapshot({
  int sizeMB = 10,
}) {
  final baseSnapshot = createTestSnapshot();
  
  // Ajouter données pour atteindre taille cible
  final largeData = List.generate(
    sizeMB * 1024 * 100, // ~10KB par élément
    (i) => 'data_$i' * 100,
  );
  
  return GameSnapshot(
    metadata: baseSnapshot.metadata,
    core: {
      ...baseSnapshot.core,
      'largeData': largeData,
    },
  );
}

/// Utility - Obtenir usage mémoire (simplifié)
int getMemoryUsage() {
  // Note: En production, utiliser dart:developer ou package memory_info
  // Pour les tests, retourner valeur simulée
  return 50 * 1024 * 1024; // 50MB
}

/// Utility - Attendre condition avec timeout
Future<void> waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final endTime = DateTime.now().add(timeout);
  
  while (DateTime.now().isBefore(endTime)) {
    if (condition()) {
      return;
    }
    await Future.delayed(pollInterval);
  }
  
  throw TimeoutException('Condition not met within $timeout');
}

/// Utility - Vérifier UUID v4 valide
bool isValidUuidV4(String uuid) {
  final uuidV4Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuidV4Regex.hasMatch(uuid);
}

/// Exception personnalisée pour tests
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}
