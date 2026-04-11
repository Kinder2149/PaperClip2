import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';

/// Service fin et sans logique métier pour l'auth Google via Firebase.
/// - Gère le cycle de vie via le SDK Firebase (streams et currentUser)
/// - Expose un ID Token Firebase à la demande
/// - Fournit un signal "user ready" pour déclencher la sync cloud
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  static final Logger _logger = Logger.forComponent('auth');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // google_sign_in v7 : seul GoogleSignIn.instance est accessible (constructeur privé).
  // initialize() doit être appelé une fois avant tout appel authenticate/signOut.
  // serverClientId = Web OAuth client ID (client_type 3) extrait de google-services.json.
  static const _kServerClientId =
      '555184834356-lr2v3kje289ghiad05uj7d2eha74kqqi.apps.googleusercontent.com';

  // Garde pour n'appeler initialize() qu'une seule fois.
  bool _googleSignInInitialized = false;

  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized || kIsWeb) return;
    await GoogleSignIn.instance.initialize(serverClientId: _kServerClientId);
    _googleSignInInitialized = true;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Déclenche un flux de connexion Google puis signe auprès de Firebase.
  /// Ne rajoute aucune règle métier.
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Sur le web, utiliser directement signInWithPopup
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final cred = await _auth.signInWithPopup(googleProvider);
        _logger.info('[AUTH] Firebase sign-in réussi (web), uid=' + (cred.user?.uid ?? '-'));
        return cred;
      }

      // Sur mobile, initialiser GoogleSignIn v7 avec le serverClientId
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? gUser = await _googleSignIn.authenticate();
      if (gUser == null) {
        _logger.warn('[AUTH] Google sign-in annule par utilisateur.');
        throw StateError('Connexion Google annulée');
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Credentials pour Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );

      // Sign-in Firebase
      final cred = await _auth.signInWithCredential(credential);
      _logger.info('[AUTH] Firebase sign-in réussi (mobile), uid=' + (cred.user?.uid ?? '-'));

      return cred;
    } on Exception catch (e) {
      _logger.error('[AUTH] Erreur signInWithGoogle: ' + e.toString());
      rethrow;
    }
  }

  /// Récupère l'ID Token Firebase actuel (JWT Google vérifiable côté serveur Firebase/Google).
  /// [forceRefresh] pour régénérer si nécessaire.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Tente d'assurer une session Firebase sans interaction utilisateur.
  /// 1) Si déjà connecté → retourne l'ID token.
  /// 2) Sinon, tente un attemptLightweightAuthentication() Google, puis signe Firebase.
  /// 3) Retourne l'ID token ou null si échec silencieux.
  Future<String?> ensureSignedInSilently() async {
    // Déjà connecté ?
    var token = await getIdToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    try {
      // Initialiser GoogleSignIn v7 avant toute tentative silencieuse
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? gUser =
          await _googleSignIn.attemptLightweightAuthentication();
      if (gUser == null) {
        _logger.warn('[AUTH] attemptLightweightAuthentication: aucun compte Google disponible.');
        return null;
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      token = await getIdToken();
      _logger.info('[AUTH] attemptLightweightAuthentication: Firebase connecté=' +
          (token != null && token.isNotEmpty).toString());

      return token;
    } catch (e) {
      _logger.warn('[AUTH] attemptLightweightAuthentication erreur: ' + e.toString());
      return null;
    }
  }

  /// Garantit que l'utilisateur est authentifié et prêt pour les opérations cloud.
  Future<bool> ensureUserReady() async {
    try {
      final token = await getIdToken();
      if (token != null && token.isNotEmpty) {
        _logger.info('[AUTH] User ready (déjà connecté)', code: 'auth_user_ready');
        return true;
      }

      _logger.info('[AUTH] Tentative connexion silencieuse', code: 'auth_silent_attempt');
      final silentToken = await ensureSignedInSilently();

      if (silentToken != null && silentToken.isNotEmpty) {
        _logger.info('[AUTH] User ready (connexion silencieuse réussie)',
            code: 'auth_user_ready_silent');
        return true;
      }

      _logger.info('[AUTH] User not ready (aucune session)', code: 'auth_user_not_ready');
      return false;
    } catch (e) {
      _logger.error('[AUTH] Erreur ensureUserReady: ' + e.toString());
      return false;
    }
  }

  /// Point d'entrée unique pour vérifier l'authentification avant toute opération cloud.
  /// Retourne le token Firebase valide ou lève une exception.
  Future<String> ensureAuthenticatedForCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.error('[AUTH] ensureAuthenticatedForCloud: utilisateur non connecté',
          code: 'auth_not_connected');
      throw StateError('NOT_AUTHENTICATED: Utilisateur non connecté');
    }

    final token = await getIdToken();
    if (token == null || token.isEmpty) {
      _logger.error('[AUTH] ensureAuthenticatedForCloud: token indisponible',
          code: 'auth_token_unavailable',
          ctx: {'uid': user.uid});
      throw StateError('TOKEN_UNAVAILABLE: Token Firebase indisponible pour uid=${user.uid}');
    }

    _logger.info('[AUTH] ensureAuthenticatedForCloud: OK',
        code: 'auth_cloud_ready',
        ctx: {'uid': user.uid, 'tokenLength': token.length});

    return token;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      if (!kIsWeb && _googleSignInInitialized) {
        await _googleSignIn.disconnect();
      }
    } catch (_) {}
  }
}
