// Tests de persistance multi-appareils — PaperClip2
//
// ─── COMMANDE DE LANCEMENT ───────────────────────────────────────────────────
//
//   flutter test test/persistence/multi_device_persistence_test.dart --timeout=120s
//
//   Ce test utilise uniquement des appels HTTP (Firebase Auth REST API +
//   Cloud Functions). Aucun SDK Firebase, aucun platform channel.
//   Fonctionne en mode VM dart pur — aucune sélection de device requise.
//
// ─── SETUP UNIQUE À FAIRE DANS FIREBASE CONSOLE ──────────────────────────────
//
//  1. Authentication → Sign-in methods → Activer "E-mail/mot de passe"
//  2. Authentication → Users → Créer (ou Reset password) pour :
//       Email    : test.keamder@gmail.com
//       Password : 6W693SZiD01
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

const _kEmail    = 'test.keamder@gmail.com';
const _kPassword = '6W693SZiD01';

/// UUID v4 fixe — reproductible entre exécutions.
const _kEnterpriseId = 'a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5';

/// Clé publique Firebase (visible dans firebase_options.dart / google-services.json).
const _kFirebaseApiKey = 'AIzaSyBJeRM2mEVBtBwzvITvnJg5tXjeOHg1Nf0';

/// URL de l'API Cloud Functions.
const _kFunctionsBase = String.fromEnvironment(
  'FUNCTIONS_API_BASE',
  defaultValue: 'https://us-central1-paperclip-98294.cloudfunctions.net/api',
);

// ─────────────────────────────────────────────────────────────────────────────
// Firebase Auth REST API
// ─────────────────────────────────────────────────────────────────────────────

/// Connexion email/password via l'API REST Firebase Identity Toolkit.
/// Retourne { idToken, localId (uid), email }.
/// Lève une exception si la connexion échoue.
Future<({String idToken, String uid, String email})> _signIn(
    String email, String password) async {
  final res = await http.post(
    Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
        '?key=$_kFirebaseApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );

  if (res.statusCode != 200) {
    throw StateError(
        'Firebase Auth REST échoué [${res.statusCode}]: ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  return (
    idToken: body['idToken'] as String,
    uid: body['localId'] as String,
    email: body['email'] as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Functions REST API
// ─────────────────────────────────────────────────────────────────────────────

Map<String, String> _authHeaders(String idToken) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

Uri _enterpriseUrl(String uid) =>
    Uri.parse('$_kFunctionsBase/enterprise/$uid');

Future<http.Response> _push(
    String uid, String idToken, Map<String, dynamic> snapshot) {
  return http.put(
    _enterpriseUrl(uid),
    headers: _authHeaders(idToken),
    body: jsonEncode({'enterpriseId': _kEnterpriseId, 'snapshot': snapshot}),
  );
}

Future<http.Response> _pull(String uid, String idToken) {
  return http.get(_enterpriseUrl(uid), headers: _authHeaders(idToken));
}

Future<http.Response> _delete(String uid, String idToken) {
  return http.delete(_enterpriseUrl(uid), headers: _authHeaders(idToken));
}

// ─────────────────────────────────────────────────────────────────────────────
// Builder de snapshot v3
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _snapshot({
  required double money,
  required int level,
  String name = 'Entreprise Test',
}) {
  // Tronquer aux millisecondes : JS Date.toISOString() produit 3 décimales,
  // Dart toIso8601String() produit 6. Le backend valide avec === strict.
  final rawNow = DateTime.now().toUtc();
  final now = DateTime.utc(rawNow.year, rawNow.month, rawNow.day,
          rawNow.hour, rawNow.minute, rawNow.second, rawNow.millisecond)
      .toIso8601String();
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

// ─────────────────────────────────────────────────────────────────────────────
// Suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  tearDownAll(() async {
    // Nettoyage : supprimer les données de test du cloud
    try {
      final session = await _signIn(_kEmail, _kPassword);
      await _delete(session.uid, session.idToken);
    } catch (_) {
      // Non bloquant
    }
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('T1 — Authentification Firebase (REST)', () {
    test('Connexion email/password → token JWT valide', () async {
      final session = await _signIn(_kEmail, _kPassword);

      expect(session.email, equals(_kEmail));
      expect(session.uid, isNotEmpty,
          reason: "L'UID Firebase doit être disponible après connexion");
      expect(session.idToken.length, greaterThan(50),
          reason: 'Le JWT Firebase doit être un token valide');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('T2 — Sauvegarde cloud', () {
    test('Push enterprise → données stockées sur le cloud', () async {
      final session = await _signIn(_kEmail, _kPassword);

      // Push
      final pushRes = await _push(
          session.uid, session.idToken,
          _snapshot(money: 42_000.0, level: 7, name: 'Entreprise T2'));
      expect(pushRes.statusCode, inInclusiveRange(200, 299),
          reason: 'Le push doit retourner 2xx: ${pushRes.body}');

      // Pull de vérification
      final pullRes = await _pull(session.uid, session.idToken);
      expect(pullRes.statusCode, equals(200));

      final body = jsonDecode(pullRes.body) as Map<String, dynamic>;
      final snap = body['snapshot'] as Map<String, dynamic>;
      expect(snap['core']?['money'],  equals(42_000.0));
      expect(snap['core']?['level'],  equals(7));
      expect(snap['metadata']?['enterpriseName'], equals('Entreprise T2'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('T3 — Multi-appareils : déconnexion → reconnexion → restauration', () {
    test('Appareil A sauvegarde → déconnexion → Appareil B restaure les données',
        () async {
      // ── Appareil A : connexion + sauvegarde ────────────────────────────
      final sessionA = await _signIn(_kEmail, _kPassword);

      await _push(sessionA.uid, sessionA.idToken,
          _snapshot(money: 99_500.0, level: 12, name: 'Entreprise Multi-Device'));

      // ── Déconnexion simulée (on oublie le token) ───────────────────────
      // sessionA est abandonné — aucun appel possible avec ce token désormais.

      // ── Appareil B : reconnexion ───────────────────────────────────────
      final sessionB = await _signIn(_kEmail, _kPassword);

      expect(sessionB.uid, equals(sessionA.uid),
          reason: "L'UID Firebase doit être le même sur les deux appareils");

      // ── Restauration ───────────────────────────────────────────────────
      final pullRes = await _pull(sessionB.uid, sessionB.idToken);
      expect(pullRes.statusCode, equals(200),
          reason: 'Le pull doit réussir après reconnexion');

      final body = jsonDecode(pullRes.body) as Map<String, dynamic>;
      final snap = body['snapshot'] as Map<String, dynamic>;

      expect(snap['core']?['money'],  equals(99_500.0),
          reason: 'Le solde sauvegardé par appareil A doit être restauré');
      expect(snap['core']?['level'],  equals(12),
          reason: 'Le niveau sauvegardé par appareil A doit être restauré');
      expect(snap['metadata']?['enterpriseName'],
          equals('Entreprise Multi-Device'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('T4 — Progression : la dernière sauvegarde écrase la précédente', () {
    test('Push V1 puis V2 → pull retourne V2', () async {
      final session = await _signIn(_kEmail, _kPassword);

      // V1
      await _push(session.uid, session.idToken,
          _snapshot(money: 1_000.0, level: 1, name: 'V1'));

      // V2 (progression simulée)
      await _push(session.uid, session.idToken,
          _snapshot(money: 250_000.0, level: 15, name: 'V2 Avancée'));

      final pullRes = await _pull(session.uid, session.idToken);
      expect(pullRes.statusCode, equals(200));

      final body = jsonDecode(pullRes.body) as Map<String, dynamic>;
      final snap = body['snapshot'] as Map<String, dynamic>;

      expect(snap['core']?['money'],  equals(250_000.0),
          reason: 'La dernière sauvegarde (V2) doit être la version active');
      expect(snap['core']?['level'],  equals(15));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('T5 — Suppression cloud', () {
    test('DELETE /enterprise → GET retourne 404', () async {
      final session = await _signIn(_kEmail, _kPassword);

      // Créer une donnée
      final pushRes = await _push(session.uid, session.idToken,
          _snapshot(money: 500.0, level: 2, name: 'À supprimer'));
      expect(pushRes.statusCode, inInclusiveRange(200, 299));

      // Supprimer
      final delRes = await _delete(session.uid, session.idToken);
      expect(delRes.statusCode, anyOf(equals(204), equals(200)),
          reason: 'La suppression doit retourner 204 ou 200');

      // Vérifier
      final afterRes = await _pull(session.uid, session.idToken);
      expect(afterRes.statusCode, equals(404),
          reason: 'Après suppression, le cloud doit retourner 404');
    });
  });
}
