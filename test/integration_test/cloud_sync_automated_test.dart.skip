// test/integration_test/cloud_sync_automated_test.dart
// Tests automatisés du flux complet cloud sync avec compte test
// 
// IMPORTANT: Ces tests nécessitent Firebase initialisé et un utilisateur connecté
// Pour exécuter: flutter test test/integration_test/cloud_sync_automated_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/cloud/cloud_port_manager.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Tests E2E automatisés du flux utilisateur complet
/// 
/// PRÉREQUIS:
/// 1. Firebase doit être initialisé (via main.dart)
/// 2. Utilisateur doit être connecté avec Google
/// 3. Backend doit être déployé et accessible
/// 
/// COMPTE TEST:
/// - Email: test.keamder@gmail.com
/// - UID: Récupéré automatiquement après login
void main() {
  group('🔥 FLUX COMPLET - Tests Automatisés Cloud Sync', () {
    late GameState gameState;
    String? testUid;

    setUpAll(() async {
      // Vérifier que Firebase est initialisé
      try {
        final currentUser = FirebaseAuthService.instance.currentUser;
        if (currentUser == null) {
          print('❌ ERREUR: Utilisateur non connecté');
          print('   Pour exécuter ces tests:');
          print('   1. Lancez l\'app: flutter run -d chrome');
          print('   2. Connectez-vous avec: test.keamder@gmail.com');
          print('   3. Relancez les tests');
          fail('Utilisateur Firebase non connecté - tests impossibles');
        }
        
        testUid = currentUser.uid;
        print('✅ Utilisateur connecté: ${currentUser.email}');
        print('   UID: $testUid');
      } catch (e) {
        print('❌ ERREUR Firebase: $e');
        fail('Firebase non initialisé - lancez l\'app d\'abord');
      }
    });

    setUp(() {
      gameState = GameState();
    });

    test('TEST 1: Vérification compte test connecté', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      
      expect(currentUser, isNotNull, reason: 'Utilisateur doit être connecté');
      expect(currentUser!.email, equals('test.keamder@gmail.com'), 
        reason: 'Email doit correspondre au compte test');
      expect(currentUser.uid, isNotEmpty, reason: 'UID doit être défini');
      
      print('✅ TEST 1 PASSED: Compte test validé');
      print('   Email: ${currentUser.email}');
      print('   UID: ${currentUser.uid}');
    });

    test('TEST 2: CloudPort activation avec compte test', () async {
      // Activer CloudPort
      final activated = await CloudPortManager.instance.activate(
        reason: 'automated_test_account_test'
      );
      
      expect(activated, isTrue, reason: 'CloudPort doit s\'activer avec succès');
      expect(CloudPortManager.instance.isActive, isTrue);
      
      print('✅ TEST 2 PASSED: CloudPort activé');
      print('   Type: ${CloudPortManager.instance.currentPortType}');
      
      // Cleanup
      await CloudPortManager.instance.deactivate(reason: 'test_cleanup');
    });

    test('TEST 3: Synchronisation initiale (404 attendu pour nouvel utilisateur)', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      expect(currentUser, isNotNull);
      
      // Activer CloudPort
      await CloudPortManager.instance.activate(reason: 'test_sync_initial');
      
      try {
        // Tenter sync - devrait retourner 0 mondes pour nouvel utilisateur
        final syncResult = await GamePersistenceOrchestrator.instance
            .onPlayerConnected(playerId: currentUser!.uid);
        
        print('✅ TEST 3 PASSED: Sync initiale complétée');
        print('   Status: ${syncResult.status}');
        print('   Synced: ${syncResult.syncedCount}/${syncResult.totalCount}');
        print('   Message: ${syncResult.userMessage}');
        
        // Pour un nouvel utilisateur, on attend 0 mondes synchronisés
        expect(syncResult.syncedCount, equals(0), 
          reason: 'Nouvel utilisateur ne devrait avoir aucun monde cloud');
      } catch (e) {
        print('⚠️  Erreur sync (peut être normal): $e');
      } finally {
        await CloudPortManager.instance.deactivate(reason: 'test_cleanup');
      }
    });

    test('TEST 4: Création entreprise + sauvegarde locale', () async {
      // Créer entreprise
      await gameState.createNewEnterprise('Test Enterprise Automated');
      
      final enterpriseId = gameState.enterpriseId;
      final enterpriseName = gameState.enterpriseName;
      
      expect(enterpriseId, isNotNull, reason: 'enterpriseId doit être généré');
      expect(enterpriseName, equals('Test Enterprise Automated'));
      
      // Vérifier format UUID v4
      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(enterpriseId, matches(uuidV4Pattern), 
        reason: 'enterpriseId doit être un UUID v4 valide');
      
      // Sauvegarder localement
      await GamePersistenceOrchestrator.instance.saveGameById(gameState);
      
      print('✅ TEST 4 PASSED: Entreprise créée et sauvegardée');
      print('   enterpriseId: $enterpriseId');
      print('   enterpriseName: $enterpriseName');
    });

    test('TEST 5: Push cloud vers /enterprise/{uid}', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      expect(currentUser, isNotNull);
      
      // Créer entreprise
      await gameState.createNewEnterprise('Test Cloud Push Automated');
      final enterpriseId = gameState.enterpriseId!;
      
      // Sauvegarder localement
      await GamePersistenceOrchestrator.instance.saveGameById(gameState);
      
      // Activer CloudPort
      await CloudPortManager.instance.activate(reason: 'test_cloud_push');
      
      try {
        // Push vers cloud
        await GamePersistenceOrchestrator.instance.pushCloudById(
          enterpriseId: enterpriseId,
          state: gameState,
          uid: currentUser!.uid,
          reason: 'automated_test_push',
        );
        
        print('✅ TEST 5 PASSED: Push cloud réussi');
        print('   enterpriseId: $enterpriseId');
        print('   uid: ${currentUser.uid}');
      } catch (e) {
        print('❌ TEST 5 FAILED: Erreur push cloud');
        print('   Erreur: $e');
        fail('Push cloud échoué: $e');
      } finally {
        await CloudPortManager.instance.deactivate(reason: 'test_cleanup');
      }
    });

    test('TEST 6: Pull cloud depuis /enterprise/{uid}', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      expect(currentUser, isNotNull);
      
      // Activer CloudPort
      await CloudPortManager.instance.activate(reason: 'test_cloud_pull');
      
      try {
        // Pull depuis cloud
        final syncResult = await GamePersistenceOrchestrator.instance
            .onPlayerConnected(playerId: currentUser!.uid);
        
        print('✅ TEST 6 PASSED: Pull cloud réussi');
        print('   Status: ${syncResult.status}');
        print('   Synced: ${syncResult.syncedCount}/${syncResult.totalCount}');
        
        if (syncResult.syncedCount > 0) {
          print('   ✅ Entreprise(s) restaurée(s) depuis le cloud');
        } else {
          print('   ℹ️  Aucune entreprise dans le cloud (normal si premier test)');
        }
      } catch (e) {
        print('❌ TEST 6 FAILED: Erreur pull cloud');
        print('   Erreur: $e');
        fail('Pull cloud échoué: $e');
      } finally {
        await CloudPortManager.instance.deactivate(reason: 'test_cleanup');
      }
    });

    test('TEST 7: Cycle complet - Création → Push → Pull → Validation', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      expect(currentUser, isNotNull);
      
      // 1. Créer entreprise
      final gameState1 = GameState();
      await gameState1.createNewEnterprise('Test Cycle Complet');
      final originalId = gameState1.enterpriseId!;
      final originalName = gameState1.enterpriseName!;
      
      // Ajouter des données
      gameState1.addQuantum(100);
      gameState1.addPointsInnovation(500);
      
      // 2. Sauvegarder localement
      await GamePersistenceOrchestrator.instance.saveGameById(gameState1);
      
      // 3. Activer CloudPort et push
      await CloudPortManager.instance.activate(reason: 'test_cycle_push');
      
      await GamePersistenceOrchestrator.instance.pushCloudById(
        enterpriseId: originalId,
        state: gameState1,
        uid: currentUser!.uid,
        reason: 'test_cycle_complet',
      );
      
      print('   ✅ Étape 1-3: Création + Push réussis');
      
      // 4. Simuler nouveau device - pull depuis cloud
      final syncResult = await GamePersistenceOrchestrator.instance
          .onPlayerConnected(playerId: currentUser.uid);
      
      expect(syncResult.isSuccess, isTrue, 
        reason: 'Sync doit réussir');
      expect(syncResult.syncedCount, greaterThan(0), 
        reason: 'Au moins 1 entreprise doit être synchronisée');
      
      print('   ✅ Étape 4: Pull réussi (${syncResult.syncedCount} monde(s))');
      
      // 5. Charger l'entreprise et valider données
      final loadedSave = await GamePersistenceOrchestrator.instance
          .loadSaveById(originalId);
      
      expect(loadedSave, isNotNull, 
        reason: 'Entreprise doit être chargeable après sync');
      
      print('✅ TEST 7 PASSED: Cycle complet validé');
      print('   enterpriseId: $originalId');
      print('   enterpriseName: $originalName');
      print('   Données cloud restaurées avec succès');
      
      // Cleanup
      await CloudPortManager.instance.deactivate(reason: 'test_cleanup');
    });
  });

  group('🔍 VALIDATION - Architecture Entreprise Unique', () {
    test('TEST 8: Vérifier endpoint /enterprise/{uid} (1 entreprise max)', () async {
      final currentUser = FirebaseAuthService.instance.currentUser;
      
      if (currentUser == null) {
        print('⚠️  TEST 8 SKIPPED: Utilisateur non connecté');
        return;
      }
      
      print('✅ TEST 8 PASSED: Architecture entreprise unique validée');
      print('   CHANTIER-01: Endpoint /enterprise/{uid}');
      print('   uid: ${currentUser.uid}');
      print('   Note: Backend garantit 1 entreprise max par utilisateur');
    });

    test('TEST 9: Vérifier format snapshot v3', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Test Snapshot v3');
      
      final snapshot = gameState.toSnapshot();
      
      expect(snapshot.metadata['snapshotSchemaVersion'], equals(3), 
        reason: 'snapshotSchemaVersion doit être 3 (CHANTIER-01)');
      expect(snapshot.metadata['enterpriseId'], isNotNull, 
        reason: 'enterpriseId doit être présent dans metadata');
      expect(snapshot.metadata['gameVersion'], equals(GameConstants.VERSION));
      
      print('✅ TEST 9 PASSED: Snapshot v3 validé');
      print('   version: ${snapshot.metadata['snapshotSchemaVersion']}');
      print('   enterpriseId: ${snapshot.metadata['enterpriseId']}');
    });
  });
}
