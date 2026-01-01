import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service fin et sans logique métier pour l'auth Google via Firebase.
/// - Gère le cycle de vie via le SDK Firebase (streams et currentUser)
/// - Expose un ID Token Firebase à la demande
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = const GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Déclenche un flux de connexion Google puis signe auprès de Firebase.
  /// Ne rajoute aucune règle métier.
  Future<UserCredential> signInWithGoogle() async {
    // 1) Demande d'auth Google
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) {
      throw StateError('Connexion Google annulée');
    }
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // 2) Credentials pour Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // 3) Sign-in Firebase
    return await _auth.signInWithCredential(credential);
  }

  /// Récupère l'ID Token Firebase actuel (JWT Google vérifiable côté serveur Firebase/Google).
  /// [forceRefresh] pour régénérer si nécessaire.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
