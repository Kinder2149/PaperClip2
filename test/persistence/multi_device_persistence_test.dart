// Tests de persistance multi-appareils — PaperClip2
//
// Ce fichier est dans test/ (pas integration_test/) pour pouvoir tourner
// sans sélection de device avec la simple commande :
//
//   flutter test test/persistence/multi_device_persistence_test.dart --timeout=120s
//
// ─── SETUP UNIQUE À FAIRE DANS FIREBASE CONSOLE ───────────────────────────────
//
//  1. Authentication → Sign-in methods → Activer "E-mail/mot de passe"
//  2. Authentication → Users → Créer (ou Reset password) pour :
//       Email    : test.keamder@gmail.com
//       Password : 6W693SZiD01
//
// ──────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/firebase_options.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';

// ────────────────────────────────────────────────────────────────────────────
// Configuration du compte de test
// ────────────────────────────────────────────────────────────────────────────

const _kEmail    = 'test.keamder@gmail.com';
const _kPassword = '6W693SZiD01';

/// UUID v4 fixe pour l'entreprise de test — reproductible entre exécutions.
const _kEnterpriseId = 'a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5';

/// URL de l'API Cloud Functions.
/// Peut être surchargée via --dart-define=FUNCTIONS_API_BASE=...
const _kFunctionsBase = String.fromEnvironment(
  'FUNCTIONS_API_BASE',
  defaultValue: 'https://us-central1-paperclip-98294.cloudfunctions.net/api',
);

// ────────────────────────────────────────────────────────────────────────────
// Builder de snapshot v3 (format attendu par le backend)
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _snapshot({
  required double money,
  required int level,
  String name = 'Entreprise Test',
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'metadata': {
      'version': 3,
      'enterpriseId': _kEnterpriseId,
      'enterpriseName': name,
      'createdAt': now,
      'lastModified': now,
      'gameVersion': '3.0.0',
      'gameMode': 'standard',
    },
    'core': {
      'enterpriseId': _kEnterpriseId,
      'enterpriseName': name,
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
// Suite
// ────────────────────────────────────────────────────────────────────────────

void main() {
  late CloudPersistenceAdapter cloud;
  late FirebaseAuth auth;

  setUpAll(() async {
    // Requis pour les plugins natifs (Firebase, platform channels) en dehors de runApp
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialisation Firebase avec les options de la plateforme courante
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth  = FirebaseAuth.instance;
    cloud = CloudPersistenceAdapter(base: _kFunctionsBase);
  });

  setUp(() async {
    // Déconnexion propre avant chaque test
    await auth.signOut();
  });

  tearDown(() async {
    await auth.signOut();
  });

  tearDownAll(() async {
    // Nettoyage final : supprimer les données de test du cloud
    try {
      await auth.signInWithEmailAndPassword(email: _kEmail, password: _kPassword);
      await cloud.deleteById(enterpriseId: _kEnterpriseId);
    } catch (_) {
      // Non bloquant — données peut-être déjà supprimées
    } finally {
      await auth.signOut();
    }
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('T1 — Authentification', () {
    test('Connexion email/password → session Firebase valide', () async {
      final cred = await auth.signInWithEmailAndPassword(
        email: _kEmail,
        password: _kPassword,
      );

      expect(cred.user, isNotNull,
          reason: 'La connexion doit retourner un User non null');
      expect(cred.user!.email, equals(_kEmail));
      expect(auth.currentUser?.uid, isNotEmpty,
          reason: "L'UID Firebase doit être disponible après connexion");

      final token = await auth.currentUser!.getIdToken();
      expect(token, isNotNull);
      expect(token!.length, greaterThan(50),
          reason: 'Le JWT Firebase doit être un token valide');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('T2 — Sauvegarde cloud', () {
    test('Push enterprise → données stockées sur le cloud', () async {
      await auth.signInWithEmailAndPassword(email: _kEmail, password: _kPassword);

      // Sauvegarde avec valeurs identifiables
      await cloud.pushById(
        enterpriseId: _kEnterpriseId,
        snapshot: _snapshot(money: 42_000.0, level: 7, name: 'Entreprise T2'),
        metadata: {'test': 'T2', 'pushedAt': DateTime.now().toIso8601String()},
      );

      // Vérification immédiate via statusById
      final status = await cloud.statusById(enterpriseId: _kEnterpriseId);
      expect(status.exists, isTrue,
          reason: 'Le cloud doit confirmer l\'existence après push');

      // Vérification des données via pullById
      final detail = await cloud.pullById(enterpriseId: _kEnterpriseId);
      expect(detail, isNotNull);
      expect(detail!.snapshot['core']?['money'],  equals(42_000.0));
      expect(detail.snapshot['core']?['level'],   equals(7));
      expect(detail.snapshot['metadata']?['enterpriseName'], equals('Entreprise T2'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('T3 — Multi-appareils : déconnexion → reconnexion → restauration', () {
    test('Appareil A sauvegarde → déconnexion → Appareil B restaure les données', () async {
      // ── Appareil A : connexion + sauvegarde ──────────────────────────────
      await auth.signInWithEmailAndPassword(email: _kEmail, password: _kPassword);
      expect(auth.currentUser, isNotNull);

      await cloud.pushById(
        enterpriseId: _kEnterpriseId,
        snapshot: _snapshot(money: 99_500.0, level: 12, name: 'Entreprise Multi-Device'),
        metadata: {'device': 'A'},
      );

      final uidA = auth.currentUser!.uid;

      // ── Déconnexion ──────────────────────────────────────────────────────
      await auth.signOut();
      expect(auth.currentUser, isNull,
          reason: 'Doit être déconnecté avant de simuler l\'appareil B');

      // ── Appareil B : reconnexion + restauration ──────────────────────────
      final credB = await auth.signInWithEmailAndPassword(
        email: _kEmail,
        password: _kPassword,
      );
      expect(credB.user!.uid, equals(uidA),
          reason: 'L\'UID Firebase doit être le même sur les deux appareils');

      final restored = await cloud.pullById(enterpriseId: _kEnterpriseId);

      expect(restored, isNotNull,
          reason: 'Le pull doit retourner les données après reconnexion');
      expect(restored!.snapshot['core']?['money'],  equals(99_500.0),
          reason: 'Le solde sauvegardé par appareil A doit être restauré');
      expect(restored.snapshot['core']?['level'],   equals(12),
          reason: 'Le niveau sauvegardé par appareil A doit être restauré');
      expect(restored.snapshot['metadata']?['enterpriseName'],
          equals('Entreprise Multi-Device'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('T4 — Progression : la dernière sauvegarde écrase la précédente', () {
    test('Push V1 puis V2 → pull retourne V2', () async {
      await auth.signInWithEmailAndPassword(email: _kEmail, password: _kPassword);

      // V1
      await cloud.pushById(
        enterpriseId: _kEnterpriseId,
        snapshot: _snapshot(money: 1_000.0, level: 1, name: 'V1'),
        metadata: {'version': 'V1'},
      );

      // V2 (progression simulée)
      await cloud.pushById(
        enterpriseId: _kEnterpriseId,
        snapshot: _snapshot(money: 250_000.0, level: 15, name: 'V2 Avancée'),
        metadata: {'version': 'V2'},
      );

      final latest = await cloud.pullById(enterpriseId: _kEnterpriseId);
      expect(latest, isNotNull);
      expect(latest!.snapshot['core']?['money'],  equals(250_000.0),
          reason: 'La dernière sauvegarde (V2) doit être la version active');
      expect(latest.snapshot['core']?['level'],   equals(15));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('T5 — Suppression cloud', () {
    test('deleteById → statusById renvoie exists=false', () async {
      await auth.signInWithEmailAndPassword(email: _kEmail, password: _kPassword);

      // Créer une donnée
      await cloud.pushById(
        enterpriseId: _kEnterpriseId,
        snapshot: _snapshot(money: 500.0, level: 2, name: 'À supprimer'),
        metadata: {},
      );
      expect((await cloud.statusById(enterpriseId: _kEnterpriseId)).exists, isTrue);

      // Supprimer
      await cloud.deleteById(enterpriseId: _kEnterpriseId);

      // Vérifier
      final after = await cloud.statusById(enterpriseId: _kEnterpriseId);
      expect(after.exists, isFalse,
          reason: 'Après suppression, le cloud ne doit plus retourner de données');
    });
  });
}
