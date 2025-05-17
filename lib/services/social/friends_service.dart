// lib/services/social/friends_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../models/social/friend_model.dart';
import '../../models/social/friend_request_model.dart';
import '../../models/social/user_stats_model.dart';
import '../user/user_profile.dart';
import '../user/user_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/social/friend_model.dart';

class FriendsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;
  final UserManager _userManager;

  // Constructeur
  FriendsService(this._userId, this._userManager);

  // Vérifier si l'utilisateur est authentifié
  bool _isUserAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Erreur: Utilisateur non authentifié');
      return false;
    }
    return true;
  }

  // Stream pour les amis
  Stream<List<FriendModel>> friendsStream() {
    if (!_isUserAuthenticated()) {
      return Stream.value([]);
    }

    debugPrint('Demande de stream friends pour l\'utilisateur: $_userId');

    try {
      return _firestore.collection('friends')
          .where(Filter.or(
          Filter('user1Id', isEqualTo: _userId),
          Filter('user2Id', isEqualTo: _userId)
      ))
          .snapshots()
          .asyncMap((snapshot) async {
        debugPrint('Snapshot friends reçu: ${snapshot.docs.length} documents');
        final List<FriendModel> friendsList = [];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final friendId = data['user1Id'] == _userId ? data['user2Id'] : data['user1Id'];

            final userDoc = await _firestore.collection('users').doc(friendId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};

              friendsList.add(FriendModel(
                id: doc.id,
                userId: friendId,
                displayName: userData['displayName'] ?? 'Utilisateur inconnu',
                photoUrl: userData['profileImageUrl'],
                lastActive: (userData['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ));
            }
          } catch (e) {
            debugPrint('Erreur lors du chargement de l\'ami: $e');
          }
        }

        return friendsList;
      })
          .handleError((error) {
        debugPrint('Erreur dans le stream friends: $error');
        return <FriendModel>[];
      })
          .asBroadcastStream(); // Rendre le stream accessible à plusieurs écouteurs
    } catch (e) {
      debugPrint('Exception dans friendsStream: $e');
      return Stream.value([]);
    }
  }

  // Stream pour les demandes d'amitié reçues
  Stream<List<FriendRequestModel>> receivedRequestsStream() {
    if (!_isUserAuthenticated()) {
      return Stream.value([]);
    }

    debugPrint('Demande de stream receivedRequests pour l\'utilisateur: $_userId');

    try {
      return _firestore.collection('friendRequests')
          .where('receiverId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint('Snapshot receivedRequests reçu: ${snapshot.docs.length} documents');
        return snapshot.docs.map((doc) => FriendRequestModel.fromFirestore(doc)).toList();
      })
          .handleError((error) {
        debugPrint('Erreur dans le stream receivedRequests: $error');
        return <FriendRequestModel>[];
      })
          .asBroadcastStream(); // Rendre le stream accessible à plusieurs écouteurs
    } catch (e) {
      debugPrint('Exception dans receivedRequestsStream: $e');
      return Stream.value([]);
    }
  }


  // Stream pour les demandes d'amitié envoyées
  Stream<List<FriendRequestModel>> sentRequestsStream() {
    if (!_isUserAuthenticated()) {
      return Stream.value([]);
    }

    try {
      return _firestore.collection('friendRequests')
          .where('senderId', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => FriendRequestModel.fromFirestore(doc)).toList())
          .asBroadcastStream(); // Rendre le stream accessible à plusieurs écouteurs
    } catch (e) {
      debugPrint('Exception dans sentRequestsStream: $e');
      return Stream.value([]);
    }
  }

  // Rechercher des utilisateurs
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.length < 3) {
      return [];
    }

    try {
      final snapshot = await _firestore.collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Filtrer les amis existants
      final friendDocs = await _firestore.collection('friends')
          .where(Filter.or(
          Filter('user1Id', isEqualTo: _userId),
          Filter('user2Id', isEqualTo: _userId)
      ))
          .get();

      // Créer un ensemble des IDs des amis
      final friendIds = <String>{};
      for (final doc in friendDocs.docs) {
        final data = doc.data();
        final friendId = data['user1Id'] == _userId ? data['user2Id'] : data['user1Id'];
        friendIds.add(friendId);
      }

      // Créer un ensemble des IDs des demandes envoyées
      final sentRequestDocs = await _firestore.collection('friendRequests')
          .where('senderId', isEqualTo: _userId)
          .get();

      final sentRequestIds = sentRequestDocs.docs
          .map((doc) => doc.data()['receiverId'] as String)
          .toSet();

      // Filtrer et convertir les résultats
      return snapshot.docs
          .where((doc) =>
      doc.id != _userId &&
          !friendIds.contains(doc.id) &&
          !sentRequestIds.contains(doc.id))
          .map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Utilisateur inconnu',
          'photoUrl': data['profileImageUrl'],
        };
      })
          .toList();
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error searching users');
      return [];
    }
  }
  // Méthode pour rechercher un utilisateur par ID
  Future<Map<String, dynamic>?> findUserById(String userId) async {
    if (!_isUserAuthenticated()) {
      return null;
    }

    try {
      debugPrint('Recherche de l\'utilisateur avec ID: $userId');

      // Vérifier d'abord si l'utilisateur existe dans la collection 'users'
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        return {
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Utilisateur inconnu',
          'photoUrl': userData['profileImageUrl'],
          'found': true,
        };
      }

      // Si l'utilisateur n'est pas trouvé par ID direct, essayer de chercher dans les profils
      final querySnapshot = await _firestore.collection('userProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profileData = querySnapshot.docs.first.data();
        return {
          'userId': userId,
          'displayName': profileData['displayName'] ?? 'Utilisateur inconnu',
          'photoUrl': profileData['profileImageUrl'],
          'found': true,
        };
      }

      debugPrint('Utilisateur non trouvé avec ID: $userId');
      return null;
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche de l\'utilisateur par ID: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error finding user by ID');
      return null;
    }
  }

// Méthode pour obtenir des suggestions d'amis
  Future<List<Map<String, dynamic>>> getSuggestedUsers() async {
    if (!_isUserAuthenticated()) {
      return [];
    }

    try {
      // Liste pour stocker les suggestions
      List<Map<String, dynamic>> suggestions = [];

      // 1. Récupérer les amis actuels et les requêtes envoyées pour les exclure
      final Set<String> excludeIds = {_userId};

      // Ajouter les amis actuels à exclure
      final friendDocs = await _firestore.collection('friends')
          .where(Filter.or(
          Filter('user1Id', isEqualTo: _userId),
          Filter('user2Id', isEqualTo: _userId)
      ))
          .get();

      for (final doc in friendDocs.docs) {
        final data = doc.data();
        final friendId = data['user1Id'] == _userId ? data['user2Id'] : data['user1Id'];
        excludeIds.add(friendId);
      }

      // Ajouter les demandes d'amitié envoyées à exclure
      final sentRequestDocs = await _firestore.collection('friendRequests')
          .where('senderId', isEqualTo: _userId)
          .get();

      for (final doc in sentRequestDocs.docs) {
        excludeIds.add(doc.data()['receiverId'] as String);
      }

      // 2. Récupérer les utilisateurs récemment actifs (limite de 5)
      final recentUsersSnapshot = await _firestore.collection('users')
          .where(FieldPath.documentId, whereNotIn: excludeIds.toList().take(10).toList()) // Limite de Firestore: 10 valeurs max
          .orderBy(FieldPath.documentId)
          .orderBy('lastLogin', descending: true)
          .limit(5)
          .get();

      for (final doc in recentUsersSnapshot.docs) {
        if (suggestions.length >= 10) break; // Max 10 suggestions au total

        final data = doc.data();
        suggestions.add({
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Utilisateur inconnu',
          'photoUrl': data['profileImageUrl'],
          'reason': 'recent',
        });

        excludeIds.add(doc.id); // Ajouter aux exclusions pour éviter les doublons
      }

      // 3. Ajouter des utilisateurs populaires (ceux avec beaucoup d'amis)
      if (suggestions.length < 10) {
        final popularUsersSnapshot = await _firestore.collection('users')
            .where(FieldPath.documentId, whereNotIn: excludeIds.toList().take(10).toList())
            .orderBy(FieldPath.documentId)
            .orderBy('friendCount', descending: true)
            .limit(5)
            .get();

        for (final doc in popularUsersSnapshot.docs) {
          if (suggestions.length >= 10) break;

          final data = doc.data();
          suggestions.add({
            'userId': doc.id,
            'displayName': data['displayName'] ?? 'Utilisateur inconnu',
            'photoUrl': data['profileImageUrl'],
            'reason': 'popular',
          });

          excludeIds.add(doc.id);
        }
      }

      // 4. Si nous avons encore besoin de plus de suggestions, ajouter des utilisateurs aléatoires
      if (suggestions.length < 10) {
        final randomUsersSnapshot = await _firestore.collection('users')
            .where(FieldPath.documentId, whereNotIn: excludeIds.toList().take(10).toList())
            .limit(10 - suggestions.length)
            .get();

        for (final doc in randomUsersSnapshot.docs) {
          final data = doc.data();
          suggestions.add({
            'userId': doc.id,
            'displayName': data['displayName'] ?? 'Utilisateur inconnu',
            'photoUrl': data['profileImageUrl'],
            'reason': 'similar_level',
          });
        }
      }

      return suggestions;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des suggestions: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error getting friend suggestions');
      return [];
    }
  }


  // Envoyer une demande d'amitié
  Future<bool> sendFriendRequest(String targetUserId, String targetName) async {
    try {
      // Vérifier si une demande existe déjà
      final existingRequest = await _firestore.collection('friendRequests')
          .where('senderId', isEqualTo: _userId)
          .where('receiverId', isEqualTo: targetUserId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false; // Demande déjà envoyée
      }

      // Récupérer les infos du profil actuel
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return false;
      }

      // Créer la demande
      await _firestore.collection('friendRequests').add({
        'senderId': _userId,
        'receiverId': targetUserId,
        'senderName': currentProfile.displayName,
        'senderPhotoUrl': currentProfile.profileImageUrl,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'envoi de la demande d\'amitié: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error sending friend request');
      return false;
    }
  }

  // Accepter une demande d'amitié
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final batch = _firestore.batch();

      // Récupérer la demande
      final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        return false;
      }

      final requestData = requestDoc.data() ?? {};
      final senderId = requestData['senderId'];

      // Mettre à jour le statut de la demande
      batch.update(_firestore.collection('friendRequests').doc(requestId), {
        'status': 'accepted',
      });

      // Créer la relation d'amitié
      batch.set(_firestore.collection('friends').doc(), {
        'user1Id': _userId,
        'user2Id': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'acceptation de la demande d\'amitié: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error accepting friend request');
      return false;
    }
  }

  // Refuser une demande d'amitié
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'declined',
      });

      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors du refus de la demande d\'amitié: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error declining friend request');
      return false;
    }
  }

  // Supprimer un ami
  Future<bool> removeFriend(String friendshipId) async {
    try {
      await _firestore.collection('friends').doc(friendshipId).delete();

      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la suppression de l\'ami: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error removing friend');
      return false;
    }
  }

  // Vérifier si un utilisateur est ami
  Future<bool> isFriend(String userId) async {
    try {
      final snapshot = await _firestore.collection('friends')
          .where(Filter.or(
          Filter('user1Id', isEqualTo: _userId),
          Filter('user2Id', isEqualTo: _userId)
      ))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final friendId = data['user1Id'] == _userId ? data['user2Id'] : data['user1Id'];
        if (friendId == userId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'amitié: $e');
      return false;
    }
  }
}