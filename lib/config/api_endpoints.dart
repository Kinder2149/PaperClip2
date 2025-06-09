// lib/config/api_endpoints.dart
// Gestion centralisée des endpoints API

import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// Classe pour la gestion centralisée des endpoints API
/// Permet d'harmoniser l'accès aux ressources et simplifier les modifications
class ApiEndpointManager {
  static final ApiEndpointManager _instance = ApiEndpointManager._internal();
  factory ApiEndpointManager() => _instance;
  
  ApiEndpointManager._internal();

  // Base de l'API
  String get baseUrl => ApiConfig.apiBaseUrl;
  
  // ===== AUTHENTIFICATION =====
  String get loginEndpoint => '/auth/login';
  String get registerEndpoint => '/auth/register';
  String get logoutEndpoint => '/auth/logout';
  String get googleOAuthEndpoint => '/auth/oauth/google'; // Nouvel endpoint pour OAuth Google
  String get providerAuthEndpoint => '/auth/provider'; // Ancien endpoint (fallback)
  String get resetPasswordEndpoint => '/auth/reset-password';
  String get resetPasswordConfirmEndpoint => '/auth/reset-password/confirm';
  String get verifyEmailEndpoint => '/auth/verify-email'; // + /:token
  String get changePasswordEndpoint => '/auth/change-password';
  String get linkGoogleEndpoint => '/auth/link/google';
  String get userProfileEndpoint => '/auth/me';
  String getUserProfileEndpoint(String userId) => '/users/$userId';

  // ===== SOCIAL =====
  String get friendsEndpoint => '/social/friends';
  String get friendRequestsEndpoint => '/social/friend-requests';
  String sendFriendRequestEndpoint(String userId) => '/social/friend-requests/$userId';
  String acceptFriendRequestEndpoint(String requestId) => '/social/friend-requests/$requestId/accept';
  String rejectFriendRequestEndpoint(String requestId) => '/social/friend-requests/$requestId/reject';
  String removeFriendEndpoint(String friendId) => '/social/friends/$friendId';
  String get leaderboardEndpoint => '/social/leaderboard';

  // ===== CONFIGURATION =====
  String get configEndpoint => '/config/active';
  String get appConfigEndpoint => '/config/app';
  String get gameConfigEndpoint => '/config/game';

  // ===== PROFIL UTILISATEUR =====
  String get profileUpdateEndpoint => '/user/profile';
  String get profileImageUploadEndpoint => '/user/profile/image';
  String get userStatsEndpoint => '/user/stats';
  String get userSavesEndpoint => '/user/profile/saves';
  String userSaveDetailsEndpoint(String saveId) => '/user/profile/saves/$saveId';
  
  // ===== JEUX & SAUVEGARDES =====
  String get savesEndpoint => '/saves';
  String saveByIdEndpoint(String saveId) => '/saves/$saveId';
  String get competitiveSavesEndpoint => '/saves/competitive';

  // ===== ANALYTICS =====
  String get analyticsEventEndpoint => '/analytics/events';
  String get analyticsSessionEndpoint => '/analytics/sessions';
  
  // Logging d'un probleme d'endpoint
  void logEndpointIssue(String endpoint, int statusCode, String message) {
    debugPrint('[API ENDPOINT ERROR] $endpoint - HTTP $statusCode - $message');
  }
}
