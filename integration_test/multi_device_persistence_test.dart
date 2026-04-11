// Tests d'intégration — Persistance multi-appareils
//
// Ces tests vérifient le cycle complet de sauvegarde/restauration :
//   1. Connexion avec le compte de test
//   2. Création d'une entreprise avec des valeurs connues
//   3. Sauvegarde vers le cloud
//   4. Déconnexion + effacement du cache local
//   5. Reconnexion
//   6. Récupération depuis le cloud et vérification des données
//
// Prérequis :
//   - Compte Firebase test actif : test.keamder@gmail.com (méthode email/password activée)
//   - Backend Cloud Functions déployé : GET/PUT /enterprise/:uid opérationnel
//   - FUNCTIONS_API_BASE dans .env ou variable d'environnement
//
// Lancement :
//   flutter test integration_test/multi_device_persistence_test.dart --timeout=120s

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ────────────────────────────────────────────────────────────────────────────
// Constantes de test
// ────────────────────────────────────────────────────────────────────────────

const _kTestEmail = 'test.keamder@gmail.com';
const _kTestPassword = '6W693SZiD01';

/// UUID v4 fixe pour l'entreprise de test (reproductible entre exécutions)
const _kTestEnterpriseId = 'a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5';

/// Snapshot v3 minimal valide pour la sauvegarde cloud
Map<String, dynamic> _buildTestSnapshot({
  required String enterpriseId,
  required double money,
  required int level,
  required String enterpriseName,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'metadata': {
      'version': 3,
      'enterpriseId': enterpriseId,
      'enterpriseName': enterpriseName,
      'createdAt': now,
      'lastModified': now,
      'gameVersion': '3.0.0',
      'gameMode': 'standard',
    },
    'core': {
      'enterpriseId': enterpriseId,
      'enterpriseName': enterpriseName,
      'level': level,
      'money': money,
      'metal': 500.0,
      'paperclips': 1000,
      'autoClipperCount': 10,
      'sellPrice': 0.25,
      'quantum': 0,
      'pointsInnovation': 0,
      'resetCount': 0,
    },
    'stats': {
      'totalPaperclipsProduced': 1000,
      'totalMoneyEarned': money,
      'totalMetalBought': 0.0,
      'playTimeSeconds': 3600,
    },
    'market': {
      'autoSellEnabled': true,
      'totalSalesRevenue': money,
      'reputation': 1.0,
    },
    'production': {
      'maintenanceCosts': 0.0,
    },
  };
}

// ────────────────────────────────────────────────────────────────────────────
// Suite de tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  // Initialisation Firebase une seule fois pour la suite
  setUpAll(() async {
    // Charger les variables d'environnement (FUNCTIONS_API_BASE)
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env optionnel si l'URL est déjà dans l'environnement
    }
    await Firebase.initializeApp();
  });

  tearDownAll(() async {
    // Déconnecter proprement après tous les tests
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  });

  group('Persistance Multi-Appareils — Cycle complet', () {
    late CloudPersistenceAdapter cloudAdapter;
    late FirebaseAuth auth;

    setUp(() async {
      auth = FirebaseAuth.instance;
      cloudAdapter = CloudPersistenceAdapter();

      // S'assurer d'être déconnecté avant chaque test
      await auth.signOut();

      // Effacer les préférences locales liées aux retries cloud
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((k) => k.startsWith('pending_identity_'))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    });

    tearDown(() async {
      await auth.signOut();
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 1 : Connexion email/password → UID Firebase disponible
    // ──────────────────────────────────────────────────────────────────────

    test('T1 — Connexion email/password → session Firebase valide', () async {
      final cred = await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      expect(cred.user, isNotNull, reason: 'La connexion doit retourner un utilisateur');
      expect(cred.user!.email, equals(_kTestEmail));
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.uid, isNotEmpty);

      final token = await auth.currentUser!.getIdToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty, reason: "Le token JWT doit être disponible après connexion");
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 2 : Sauvegarde cloud → Données persistées
    // ──────────────────────────────────────────────────────────────────────

    test('T2 — Sauvegarde enterprise → Cloud stocke les données', () async {
      // Connexion
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );
      expect(auth.currentUser, isNotNull);

      // Snapshot de test avec valeurs identifiables
      final snapshot = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 42000.0,
        level: 7,
        enterpriseName: 'Entreprise Test T2',
      );

      // Push vers le cloud
      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshot,
        metadata: {
          'pushedAt': DateTime.now().toIso8601String(),
          'testRun': 'T2',
        },
      );

      // Vérification : récupérer et valider
      final pulled = await cloudAdapter.pullById(enterpriseId: _kTestEnterpriseId);
      expect(pulled, isNotNull, reason: 'Le pull doit retourner les données sauvegardées');
      expect(pulled!.snapshot['core']?['money'], equals(42000.0));
      expect(pulled.snapshot['core']?['level'], equals(7));
      expect(pulled.snapshot['metadata']?['enterpriseName'], equals('Entreprise Test T2'));
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 3 : Déconnexion + reconnexion → Données cloud récupérées
    // ──────────────────────────────────────────────────────────────────────

    test('T3 — Déconnexion puis reconnexion → Entreprise récupérée du cloud', () async {
      // === APPAREIL A : Connexion + sauvegarde ===
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      final snapshotA = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 99500.0,
        level: 12,
        enterpriseName: 'Entreprise Multi-Device',
      );

      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshotA,
        metadata: {'pushedAt': DateTime.now().toIso8601String(), 'device': 'A'},
      );

      // Vérification intermédiaire
      final statusAfterPush = await cloudAdapter.statusById(enterpriseId: _kTestEnterpriseId);
      expect(statusAfterPush.exists, isTrue, reason: 'Le cloud doit confirmer l\'existence après push');

      // === Déconnexion ===
      await auth.signOut();
      expect(auth.currentUser, isNull, reason: 'Doit être déconnecté');

      // Effacer le cache local des sauvegardes (simule appareil B ou réinstallation)
      try {
        final mgr = await LocalSaveGameManager.getInstance();
        await mgr.deleteSave(_kTestEnterpriseId);
      } catch (_) {
        // Normal si pas de sauvegarde locale
      }

      // === APPAREIL B : Reconnexion + restauration ===
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );
      expect(auth.currentUser, isNotNull, reason: 'La reconnexion doit réussir');

      // Pull depuis le cloud
      final restoredDetail = await cloudAdapter.pullById(enterpriseId: _kTestEnterpriseId);

      expect(restoredDetail, isNotNull, reason: 'Le pull doit retourner les données après reconnexion');
      expect(
        restoredDetail!.snapshot['core']?['money'],
        equals(99500.0),
        reason: 'Le solde doit être celui sauvegardé par appareil A',
      );
      expect(
        restoredDetail.snapshot['core']?['level'],
        equals(12),
        reason: 'Le niveau doit être celui sauvegardé par appareil A',
      );
      expect(
        restoredDetail.snapshot['metadata']?['enterpriseName'],
        equals('Entreprise Multi-Device'),
        reason: 'Le nom de l\'entreprise doit être préservé',
      );
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 4 : Mise à jour depuis appareil B → Appareil A récupère la version la plus récente
    // ──────────────────────────────────────────────────────────────────────

    test('T4 — Mise à jour cloud (device B) → Device A récupère version récente', () async {
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      // Device A : sauvegarde initiale
      final snapshotV1 = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 1000.0,
        level: 1,
        enterpriseName: 'Entreprise V1',
      );
      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshotV1,
        metadata: {'version': 'v1'},
      );

      // Simuler avancement (device B joue pendant 1h)
      await Future.delayed(const Duration(milliseconds: 100)); // garder le test rapide

      // Device B : sauvegarde avec progression
      final snapshotV2 = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 250000.0,
        level: 15,
        enterpriseName: 'Entreprise V2 Avancée',
      );
      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshotV2,
        metadata: {'version': 'v2'},
      );

      // Device A : pull → doit obtenir V2
      final latest = await cloudAdapter.pullById(enterpriseId: _kTestEnterpriseId);
      expect(latest, isNotNull);
      expect(latest!.snapshot['core']?['money'], equals(250000.0),
          reason: 'Device A doit récupérer la version la plus récente (V2)');
      expect(latest.snapshot['core']?['level'], equals(15));
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 5 : Suppression cloud → Données effacées
    // ──────────────────────────────────────────────────────────────────────

    test('T5 — Suppression enterprise cloud → Plus de données disponibles', () async {
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      // Créer d'abord une donnée
      final snapshot = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 500.0,
        level: 2,
        enterpriseName: 'Entreprise à supprimer',
      );
      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshot,
        metadata: {},
      );

      // Vérifier qu'elle existe
      final beforeDelete = await cloudAdapter.statusById(enterpriseId: _kTestEnterpriseId);
      expect(beforeDelete.exists, isTrue);

      // Supprimer
      await cloudAdapter.deleteById(enterpriseId: _kTestEnterpriseId);

      // Vérifier qu'elle n'existe plus
      final afterDelete = await cloudAdapter.statusById(enterpriseId: _kTestEnterpriseId);
      expect(afterDelete.exists, isFalse,
          reason: 'Après suppression, le cloud ne doit plus retourner de données');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Test 6 : listParties() → Retourne l'entreprise existante
    // ──────────────────────────────────────────────────────────────────────

    test('T6 — listParties() → Retourne l\'entreprise du compte connecté', () async {
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      // Créer une entreprise
      final snapshot = _buildTestSnapshot(
        enterpriseId: _kTestEnterpriseId,
        money: 750.0,
        level: 3,
        enterpriseName: 'Entreprise listable',
      );
      await cloudAdapter.pushById(
        enterpriseId: _kTestEnterpriseId,
        snapshot: snapshot,
        metadata: {},
      );

      // Lister les entreprises
      final entries = await cloudAdapter.listParties();
      expect(entries, isNotEmpty, reason: 'La liste ne doit pas être vide après création');
      expect(
        entries.any((e) => e.enterpriseId == _kTestEnterpriseId),
        isTrue,
        reason: 'L\'entreprise créée doit apparaître dans la liste',
      );
    });

    // ──────────────────────────────────────────────────────────────────────
    // Nettoyage final : supprimer les données de test du cloud
    // ──────────────────────────────────────────────────────────────────────

    test('CLEANUP — Suppression des données de test cloud', () async {
      await auth.signInWithEmailAndPassword(
        email: _kTestEmail,
        password: _kTestPassword,
      );

      try {
        await cloudAdapter.deleteById(enterpriseId: _kTestEnterpriseId);
      } catch (_) {
        // Normal si déjà supprimé
      }

      final status = await cloudAdapter.statusById(enterpriseId: _kTestEnterpriseId);
      expect(status.exists, isFalse, reason: 'Le nettoyage doit réussir');
    });
  });
}
