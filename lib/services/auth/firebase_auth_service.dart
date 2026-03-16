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
  // IMPORTANT: utiliser le client Web OAuth pour forcer l'émission d'un idToken valide côté Android
  // ID client Web (auto-created by Google Service) extrait de google-services.json
  // client_id: 555184834356-lr2v3kje289ghiad05uj7d2eha74kqqi.apps.googleusercontent.com
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize(
        serverClientId: '555184834356-lr2v3kje289ghiad05uj7d2eha74kqqi.apps.googleusercontent.com',
      );
      _initialized = true;
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Déclenche un flux de connexion Google puis signe auprès de Firebase.
  /// Ne rajoute aucune règle métier.
  Future<UserCredential> signInWithGoogle() async {
    // 1) Demande d'auth Google
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? gUser = await _googleSignIn.authenticate();
      if (gUser == null) {
        _logger.warn('[AUTH] Google sign-in annule par utilisateur.');
        throw StateError('Connexion Google annulée');
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // 2) Credentials pour Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );

      // 3) Sign-in Firebase
      final cred = await _auth.signInWithCredential(credential);
      _logger.info('[AUTH] Firebase sign-in réussi, uid='+ (cred.user?.uid ?? '-'));
      
      return cred;
    } on Exception catch (e) {
      _logger.error('[AUTH] Erreur signInWithGoogle: '+e.toString());
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
      // Tentative de session Google silencieuse
      await _ensureInitialized();
      final GoogleSignInAccount? gUser = await _googleSignIn.attemptLightweightAuthentication();
      if (gUser == null) {
        // Pas de session Google disponible en silence
        _logger.warn('[AUTH] attemptLightweightAuthentication: aucun compte Google disponible.');
        return null;
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      // Récupérer le token après sign-in silencieux
      token = await getIdToken();
      _logger.info('[AUTH] attemptLightweightAuthentication: Firebase connecté='+ (token != null && token.isNotEmpty).toString());
      
      return token;
    } catch (e) {
      // Rester discret mais journaliser l'erreur pour diagnostic
      _logger.warn('[AUTH] attemptLightweightAuthentication erreur: '+e.toString());
      return null;
    }
  }

  /// MISSION STABILISATION: Garantit que l'utilisateur est authentifié et prêt pour les opérations cloud.
  /// Cette méthode est le point d'entrée unique pour vérifier l'état "user ready".
  /// 
  /// Retourne true si l'utilisateur est connecté avec un token valide.
  /// Tente une connexion silencieuse si nécessaire.
  Future<bool> ensureUserReady() async {
    try {
      // Vérifier si déjà connecté avec token valide
      final token = await getIdToken();
      if (token != null && token.isNotEmpty) {
        _logger.info('[AUTH] User ready (déjà connecté)', code: 'auth_user_ready');
        return true;
      }

      // Tenter connexion silencieuse
      _logger.info('[AUTH] Tentative connexion silencieuse', code: 'auth_silent_attempt');
      final silentToken = await ensureSignedInSilently();
      
      if (silentToken != null && silentToken.isNotEmpty) {
        _logger.info('[AUTH] User ready (connexion silencieuse réussie)', code: 'auth_user_ready_silent');
        return true;
      }

      // Pas de session disponible
      _logger.info('[AUTH] User not ready (aucune session)', code: 'auth_user_not_ready');
      return false;
    } catch (e) {
      _logger.error('[AUTH] Erreur ensureUserReady: '+e.toString());
      return false;
    }
  }

  /// CORRECTION AUDIT: Point d'entrée unique pour vérifier l'authentification avant toute opération cloud.
  /// Cette méthode centralise TOUTES les vérifications d'identité et lève une exception explicite en cas d'échec.
  /// 
  /// Retourne le token Firebase valide ou lève une exception.
  /// 
  /// Exceptions:
  /// - StateError('NOT_AUTHENTICATED') si aucun utilisateur connecté
  /// - StateError('TOKEN_UNAVAILABLE') si le token ne peut pas être récupéré
  Future<String> ensureAuthenticatedForCloud() async {
    // Vérifier utilisateur connecté
    final user = _auth.currentUser;
    if (user == null) {
      _logger.error('[AUTH] ensureAuthenticatedForCloud: utilisateur non connecté', code: 'auth_not_connected');
      throw StateError('NOT_AUTHENTICATED: Utilisateur non connecté');
    }

    // Récupérer token Firebase
    final token = await getIdToken();
    if (token == null || token.isEmpty) {
      _logger.error('[AUTH] ensureAuthenticatedForCloud: token indisponible', code: 'auth_token_unavailable', ctx: {
        'hasUser': user != null,
        'uid': user.uid,
      });
      throw StateError('TOKEN_UNAVAILABLE: Token Firebase indisponible pour uid=${user.uid}');
    }

    _logger.info('[AUTH] ensureAuthenticatedForCloud: OK', code: 'auth_cloud_ready', ctx: {
      'uid': user.uid,
      'tokenLength': token.length,
    });

    return token;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
    } catch (_) {}
  }
}
