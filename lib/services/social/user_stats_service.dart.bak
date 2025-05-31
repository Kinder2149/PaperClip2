// lib/services/social/user_stats_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../models/social/user_stats_model.dart';
import '../../models/game_state.dart';
import '../user/user_manager.dart';

class UserStatsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;
  final UserManager _userManager;

  // Durée minimale entre deux mises à jour de stats
  static const Duration _minUpdateInterval = Duration(minutes: 5);
  DateTime _lastUpdate = DateTime.now().subtract(Duration(minutes: 10));

  // Constructeur
  UserStatsService(this._userId, this._userManager);

  // Mettre à jour les statistiques publiques
  Future<bool> updatePublicStats(GameState gameState) async {
    try {
      // Vérifier l'intervalle de mise à jour
      final now = DateTime.now();
      if (now.difference(_lastUpdate) < _minUpdateInterval) {
        return false; // Trop tôt pour mettre à jour
      }

      _lastUpdate = now;

      // Récupérer le profile utilisateur
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return false;
      }

      // Créer l'objet de statistiques
      final stats = UserStatsModel.fromGameState(
        _userId,
        currentProfile.displayName,
        gameState,
      );

      // Enregistrer dans Firestore
      await _firestore.collection('users').doc(_userId).set({
        'displayName': currentProfile.displayName,
        'profileImageUrl': currentProfile.profileImageUrl,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Enregistrer les statistiques publiques
      await _firestore.collection('users').doc(_userId)
          .collection('publicStats').doc('game')
          .set(stats.toJson());

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error updating public stats');
      return false;
    }
  }

  // Obtenir les statistiques d'un ami
  Future<UserStatsModel?> getFriendStats(String friendId) async {
    try {
      // Récupérer les informations de base du profil
      final userDoc = await _firestore.collection('users').doc(friendId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() ?? {};

      // Récupérer les statistiques publiques
      final statsDoc = await _firestore.collection('users').doc(friendId)
          .collection('publicStats').doc('game').get();

      if (!statsDoc.exists) {
        return null;
      }

      final statsData = statsDoc.data() ?? {};

      return UserStatsModel(
        userId: friendId,
        displayName: userData['displayName'] ?? 'Utilisateur inconnu',
        totalPaperclips: statsData['totalPaperclips'] ?? 0,
        level: statsData['level'] ?? 1,
        money: (statsData['money'] as num?)?.toDouble() ?? 0.0,
        bestScore: statsData['bestScore'] ?? 0,
        efficiency: (statsData['efficiency'] as num?)?.toDouble() ?? 0.0,
        upgradesBought: statsData['upgradesBought'] ?? 0,
        lastUpdated: (statsData['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des statistiques de l\'ami: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error getting friend stats');
      return null;
    }
  }

  // Comparer les statistiques avec un ami
  Future<Map<String, dynamic>?> compareWithFriend(String friendId, GameState gameState) async {
    try {
      // Récupérer les statistiques de l'ami
      final friendStats = await getFriendStats(friendId);
      if (friendStats == null) {
        return null;
      }

      // Récupérer le profile utilisateur
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return null;
      }

      // Créer nos statistiques
      final myStats = UserStatsModel.fromGameState(
        _userId,
        currentProfile.displayName,
        gameState,
      );

      // Effectuer la comparaison
      return {
        'me': {
          'userId': _userId,
          'displayName': currentProfile.displayName,
          'photoUrl': currentProfile.profileImageUrl,
        },
        'friend': {
          'userId': friendId,
          'displayName': friendStats.displayName,
        },
        'comparison': myStats.compareWith(friendStats),
      };
    } catch (e, stack) {
      debugPrint('Erreur lors de la comparaison avec l\'ami: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error comparing with friend');
      return null;
    }
  }
}