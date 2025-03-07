import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Initialisation de Firebase
  static Future<void> initialiser() async {
    await Firebase.initializeApp();
  }

  // Authentification Google
  Future<UserCredential?> connexionGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Erreur de connexion Google: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> deconnexion() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Sauvegarde Cloud
  Future<void> sauvegarderCloud(String userId, Map<String, dynamic> donnees) async {
    try {
      await _firestore
        .collection('sauvegardes')
        .doc(userId)
        .set({
          'donnees': donnees,
          'derniereMiseAJour': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      print('Erreur de sauvegarde cloud: $e');
      throw e;
    }
  }

  // Chargement Cloud
  Future<Map<String, dynamic>?> chargerCloud(String userId) async {
    try {
      final doc = await _firestore
        .collection('sauvegardes')
        .doc(userId)
        .get();

      if (doc.exists) {
        return doc.data()?['donnees'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur de chargement cloud: $e');
      return null;
    }
  }

  // Classement
  Future<void> mettreAJourClassement(String userId, Map<String, dynamic> stats) async {
    try {
      await _firestore
        .collection('classement')
        .doc(userId)
        .set({
          'stats': stats,
          'derniereMiseAJour': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      print('Erreur de mise à jour du classement: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenirClassement() async {
    try {
      final snapshot = await _firestore
        .collection('classement')
        .orderBy('stats.trombonesProduits', descending: true)
        .limit(100)
        .get();

      return snapshot.docs
        .map((doc) => {
          'userId': doc.id,
          ...doc.data(),
        })
        .toList();
    } catch (e) {
      print('Erreur de récupération du classement: $e');
      return [];
    }
  }

  // Achievements
  Future<void> debloquerAchievement(String userId, String achievementId) async {
    try {
      await _firestore
        .collection('achievements')
        .doc(userId)
        .set({
          achievementId: true,
        }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur de déblocage d\'achievement: $e');
    }
  }

  Future<List<String>> obtenirAchievements(String userId) async {
    try {
      final doc = await _firestore
        .collection('achievements')
        .doc(userId)
        .get();

      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)
          .entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();
      }
      return [];
    } catch (e) {
      print('Erreur de récupération des achievements: $e');
      return [];
    }
  }
} 