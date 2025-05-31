// lib/services/user/user_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'user_profile.dart';
import 'google_auth_service.dart';
import '../../models/game_config.dart';
import '../save/save_system.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import '../social/friends_service.dart';
import '../social/user_stats_service.dart';
import '../../models/social/user_stats_model.dart';
import '../../models/game_state.dart';
import '../../models/game_config.dart';

// Import des nouveaux services API
import '../api/api_services.dart';

class UserManager {
  static UserManager? _instance;
  
  factory UserManager({
    required AuthService authService,
    required StorageService storageService,
    required AnalyticsService analyticsService,
    required SocialService socialService,
    required SaveService saveService,
  }) {
    _instance ??= UserManager._internal(
      authService: authService,
      storageService: storageService,
      analyticsService: analyticsService,
      socialService: socialService,
      saveService: saveService,
    );
    return _instance!;
  }

  // Clés pour SharedPreferences
  static const String _userProfileKey = 'user_profile';

  // Services API
  final AuthService _authService;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  final SocialService _socialService;
  final SaveService _saveService;

  // État interne
  UserProfile? _currentProfile;
  bool _initialized = false;
  BuildContext? _context;
  
  // Services sociaux
  FriendsService? _friendsService;
  UserStatsService? _userStatsService;
  
  // Système de sauvegarde
  SaveSystem? _saveSystem;
  
  // Notificateurs et événements de changement
  final ValueNotifier<UserProfile?> profileChanged = ValueNotifier<UserProfile?>(null);

  // Constructeur interne
  UserManager._internal({
    required AuthService authService,
    required StorageService storageService,
    required AnalyticsService analyticsService,
    required SocialService socialService,
    required SaveService saveService,
  }) : 
    _authService = authService,
    _storageService = storageService,
    _analyticsService = analyticsService,
    _socialService = socialService,
    _saveService = saveService;

  // Setter pour injecter SaveSystem
  void setSaveSystem(SaveSystem saveSystem) {
    _saveSystem = saveSystem;
    debugPrint('UserManager: SaveSystem injecté');
  }

  // Setter pour le contexte
  void setContext(BuildContext context) {
    _context = context;
  }

  // Initialisation
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiser les services API si nécessaire
      
      // Charger le profil actuel
      await _loadCurrentProfile();

      // Vérifier la connexion avec le service d'authentification
      final isSignedIn = _authService.isAuthenticated;
      final userId = _authService.userId;

      if (isSignedIn && userId != null) {
        if (_currentProfile != null && _currentProfile!.userId != userId) {
          // Connecté mais profil local différent
          debugPrint('Utilisateur connecté avec un ID différent du profil local');
          // Charger le profil du serveur
          await _loadProfileFromServer(userId);
        } else if (_currentProfile == null) {
          // Connecté mais pas de profil local
          await _loadProfileFromServer(userId);
        }
      }

      // Initialiser les services sociaux si l'utilisateur est connecté
      if (_currentProfile != null) {
        try {
          _friendsService = FriendsService(_currentProfile!.userId, this);
          _userStatsService = UserStatsService(_currentProfile!.userId, this);
          
          // Définir l'ID utilisateur pour l'analytique
          await _analyticsService.setUserId(_currentProfile!.userId);
          
          debugPrint('Services sociaux initialisés pour l\'utilisateur: ${_currentProfile!.userId}');
        } catch (e) {
          debugPrint('Erreur lors de l\'initialisation des services sociaux: $e');
          // Ne pas bloquer l'initialisation si les services sociaux échouent
        }
      }

      _initialized = true;
      debugPrint('UserManager initialisé avec succès');
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'initialisation de UserManager: $e');
      // Enregistrer l'erreur
      try {
        _analyticsService.recordError(e, stack, reason: 'UserManager init error');
      } catch (_) {}
      rethrow;
    }
  }

  // Getters
  UserProfile? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;
  FriendsService? get friendsService => _friendsService;
  UserStatsService? get userStatsService => _userStatsService;

  // Création d'un profil
  Future<UserProfile?> createProfile(String displayName) async {
    try {
      // Créer un profil via l'API
      final result = await _authService.register(displayName, "", "");
      
      if (result is Map<String, dynamic> && result['success'] != true) {
        debugPrint('Échec de la création du profil: ${result['message']}');
        return null;
      }
      
      // Récupérer les données du profil depuis le serveur
      final userId = _authService.userId;
      if (userId == null) {
        debugPrint('ID utilisateur non disponible après création du profil');
        return null;
      }
      
      // Charger le profil depuis le serveur
      await _loadProfileFromServer(userId);
      
      // Initialiser les services sociaux
      if (_currentProfile != null) {
        _friendsService = FriendsService(_currentProfile!.userId, this);
        _userStatsService = UserStatsService(_currentProfile!.userId, this);
        
        // Définir l'ID utilisateur pour l'analytique
        await _analyticsService.setUserId(_currentProfile!.userId);
        
        // Notifier
        profileChanged.value = _currentProfile;
      }
      
      return _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile creation error');
      rethrow;
    }
  }

  // Connexion avec Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // Utiliser le service d'authentification pour se connecter avec Google
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        debugPrint('Connexion Google échouée');
        return null;
      }
      
      // Récupérer l'ID utilisateur du service d'authentification
      final userId = _authService.userId;
      
      if (userId == null) {
        debugPrint('Impossible de récupérer l\'ID utilisateur après connexion');
        return null;
      }
      
      // Charger le profil depuis le serveur
      await _loadProfileFromServer(userId);
      
      if (_currentProfile == null) {
        debugPrint('Profil non trouvé après connexion Google');
        return null;
      }
      
      // Initialiser les services sociaux
      _friendsService = FriendsService(_currentProfile!.userId, this);
      _userStatsService = UserStatsService(_currentProfile!.userId, this);
      
      // Définir l'ID utilisateur pour l'analytique
      await _analyticsService.setUserId(_currentProfile!.userId);
      
      return _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la connexion avec Google: $e');
      _analyticsService.recordError(e, stack, reason: 'Google sign in error');
      return null;
    }
  }

  // Mise à jour des statistiques publiques
  Future<void> updatePublicStats(GameState gameState) async {
    if (_currentProfile == null || _userStatsService == null) return;
    
    try {
      await _userStatsService.updatePublicStats(gameState);
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques publiques: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Public stats update error');
    }
  }

  // Upload d'une image de profil à partir d'un fichier
  Future<String?> uploadProfileImageFromFile(File imageFile) async {
    if (_currentProfile == null) return null;

    try {
      // Upload de l'image
      final imageUrl = await _storageService.uploadProfileImage(
        imageFile,
        _currentProfile!.userId,
      );
      
      // Mettre à jour le profil
      _currentProfile!.profileImageUrl = imageUrl;
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Mettre à jour dans le backend
      await _authService.updateProfile({
        'profile_image_url': imageUrl,
      });
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      return imageUrl;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'upload de l\'image de profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile image upload error');
      return null;
    }
    }
  }

  // Lier le profil à Google
  Future<bool> linkProfileToGoogle() async {
    if (_currentProfile == null) return false;

    try {
      // Utiliser le service d'authentification pour lier le compte Google
      final result = await _authService.linkWithGoogle();
      
      if (result['success'] != true) {
        debugPrint('Liaison avec Google échouée: ${result['message']}');
        return false;
      }
      
      // Récupérer les informations utilisateur mises à jour
      final userData = await _authService.getUserProfile(_currentProfile!.userId);
      
      if (userData['success'] != true) {
        debugPrint('Impossible de récupérer les informations utilisateur après liaison');
        return false;
      }
      
      // Mettre à jour le profil local
      _currentProfile!.googleId = userData['google_id'];
      _currentProfile!.email = userData['email'];
      _currentProfile!.lastUpdated = DateTime.now();
      
      if (_currentProfile!.profileImageUrl == null && userData['profile_image_url'] != null) {
        _currentProfile!.profileImageUrl = userData['profile_image_url'];
      }
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      // Log événement
      _analyticsService.logEvent('profile_linked_with_google', {
        'user_id': _currentProfile!.userId,
      });
      
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la liaison du profil à Google: $e');
      _analyticsService.recordError(e, stack, reason: 'Google link error');
      return false;
    }
  }

  // Charger le profil depuis le serveur en utilisant l'ID utilisateur
  Future<void> _loadProfileFromServer(String userId) async {
    try {
      // Rechercher le profil via l'API
      final userData = await _authService.getUserProfile(userId);

      if (userData['success'] == true && userData['data'] != null) {
        // Créer un profil à partir des données de l'API
        final profile = UserProfile.fromMap(userData['data']);

        // Sauvegarder le profil localement
        await _saveProfileLocally(profile);

        // Mettre à jour l'état interne
        _currentProfile = profile;
        profileChanged.value = profile;

        debugPrint('Profil chargé depuis le serveur: ${profile.username}');
      } else {
        debugPrint('Aucun profil trouvé sur le serveur pour cet ID utilisateur');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement du profil depuis le serveur: $e');
      _analyticsService.recordError(e, stack, reason: 'Server profile load error');
    }
  }

  // Sauvegarde du profil dans le cloud
  Future<void> _saveProfileToCloud(UserProfile profile) async {
    try {
      // Mettre à jour le profil via le service d'authentification
      final result = await _authService.updateUserProfile(profile.toMap());
      
      if (!result.success) {
        debugPrint('Échec de la mise à jour du profil: ${result.message}');
      } else {
        debugPrint('Profil sauvegardé dans le cloud: ${profile.userId}');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde du profil dans le cloud: $e');
      _analyticsService.recordError(e, stack, reason: 'Cloud profile save error');
    }
  }

  // Chargement du profil actuel
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        _currentProfile = UserProfile.fromJson(json.decode(profileJson));
        debugPrint('Profil chargé: ${_currentProfile!.displayName}');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement du profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Profile loading error');
    }
  }

  // Sauvegarde du profil localement
  Future<void> _saveProfileLocally(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, json.encode(profile.toJson()));
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde locale du profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Local profile saving error');
    }
  }

  // Upload d'une image de profil
  Future<String?> uploadProfileImage() async {
    if (_currentProfile == null) return null;

    try {
      // Sélectionner une image depuis la galerie
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        debugPrint('Aucune image sélectionnée');
        return null;
      }
      
      // Lire le fichier
      final imageFile = File(pickedFile.path);
      
      // Uploader l'image via le service de stockage
      final imageUrl = await _storageService.uploadProfileImage(imageFile, _currentProfile!.userId);
      
      if (imageUrl == null) {
        debugPrint('Échec de l\'upload de l\'image de profil');
        return null;
      }
      
      // Mettre à jour le profil
      _currentProfile!.profileImageUrl = imageUrl;
      _currentProfile!.lastUpdated = DateTime.now();
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Mettre à jour dans le backend
      await _saveProfileToCloud(_currentProfile!);
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      return imageUrl;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'upload de l\'image de profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile image upload error');
      return null;
    }
  }

  // Ajouter une sauvegarde au profil
  Future<void> addSaveToProfile(String saveId, GameMode mode) async {
    if (_currentProfile == null) return;

    try {
      // Ajouter l'ID de sauvegarde
      if (mode == GameMode.COMPETITIVE) {
        _currentProfile!.addCompetitiveSaveId(saveId);
      } else {
        _currentProfile!.addInfiniteSaveId(saveId);
      }
      
      // Sauvegarder
      await _saveProfileLocally(_currentProfile!);
      
      if (_currentProfile!.googleId != null) {
        await _saveProfileToCloud(_currentProfile!);
      }
      
      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'ajout de la sauvegarde au profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Add save error');
      rethrow;
    }
  }

  // Supprimer une sauvegarde du profil
  Future<void> removeSaveFromProfile(String saveId) async {
    if (_currentProfile == null) return;

    try {
      // Supprimer l'ID de sauvegarde
      _currentProfile!.removeSaveId(saveId);
      
      // Sauvegarder
      await _saveProfileLocally(_currentProfile!);
      
      if (_currentProfile!.googleId != null) {
        await _saveProfileToCloud(_currentProfile!);
      }
      
      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la suppression de la sauvegarde du profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Remove save error');
    }
  }

  // Synchroniser avec le cloud
  Future<bool> syncWithCloud() async {
    if (_currentProfile == null) {
      debugPrint('Aucun profil actif à synchroniser');
      return false;
    }

    try {
      // Vérifier si l'utilisateur est authentifié
      if (!_authService.isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible de synchroniser');
        return false;
      }
      
      // Synchroniser le profil
      await _saveProfileToCloud(_currentProfile!);
      
      // Synchroniser les sauvegardes
      if (_saveSystem != null) {
        final result = await _saveService.syncAllSaves(_currentProfile!.userId);
        if (result is Map<String, dynamic> && result['success'] != true) {
          debugPrint('Échec de la synchronisation des sauvegardes: ${result['message']}');
          return false;
        }
        debugPrint('Synchronisation cloud complète: profil et sauvegardes');
        return true;
      } else {
        debugPrint('SaveSystem non disponible');
        return true; // Le profil a été synchronisé même si les sauvegardes ne l'ont pas été
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la synchronisation avec le cloud: $e');
      _analyticsService.recordError(e, stack, reason: 'Cloud sync error');
      return false;
    }
  }

  // Vérifier si une partie compétitive peut être créée
  Future<bool> canCreateCompetitiveSave() async {
    await initialize(); // S'assurer que UserManager est initialisé
    return _currentProfile == null || _currentProfile!.canCreateCompetitiveSave();
  }
  
  // Sauvegarder le profil dans le cloud
  // Mettre à jour le profil
  Future<void> updateProfile({
    String? username,
    String? email,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentProfile == null) return;
    
    try {
      // Préparer les données de mise à jour
      final updateData = <String, dynamic>{};
      
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
      
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      // Mettre à jour via l'API
      final result = await _authService.updateProfile(updateData);
      
      if (result is Map<String, dynamic> && result['success'] != true) {
        debugPrint('Erreur lors de la mise à jour du profil: ${result['message']}');
        return;
      }
      
      // Mettre à jour le profil local
      if (username != null) _currentProfile!.username = username;
      if (email != null) _currentProfile!.email = email;
      if (profileImageUrl != null) _currentProfile!.profileImageUrl = profileImageUrl;
      
      _currentProfile!.lastUpdated = DateTime.now();
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      // Log événement
      _analyticsService.logEvent('profile_updated', {
        'user_id': _currentProfile!.userId,
      });
    } catch (e, stack) {
      debugPrint('Exception lors de la mise à jour du profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile update error');
    }
  }

  // Obtenir les sauvegardes du profil
  Future<List<String>> getProfileSaveIds({GameMode? mode}) async {
    if (_currentProfile == null) {
      return [];
    }

    if (mode == GameMode.COMPETITIVE) {
      return _currentProfile!.competitiveSaveIds;
    } else if (mode == GameMode.INFINITE) {
      return _currentProfile!.infiniteSaveIds;
    } else {
      return [..._currentProfile!.infiniteSaveIds, ..._currentProfile!.competitiveSaveIds];
    }
  }

  // Mettre à jour les statistiques globales
  Future<void> updateGlobalStats(Map<String, dynamic> newStats) async {
    if (_currentProfile == null) return;

    try {
      // Mettre à jour les statistiques locales
      _currentProfile!.updateGlobalStats(newStats);
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Mettre à jour les statistiques dans le backend via le service social
      final result = await _socialService.updateUserStats(_currentProfile!.userId, newStats);
      
      if (result is Map<String, dynamic> && result['success'] != true) {
        debugPrint('Échec de la mise à jour des statistiques sur le serveur: ${result['message']}');
      }
      
      // Enregistrer l'événement d'analytique
      _analyticsService.logEvent('stats_updated', newStats);
      
      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      _analyticsService.recordError(e, stack, reason: 'Stats update error');
    }
  }

  // Méthode pour mettre à jour le profil complet
  Future<void> updateProfileObject(UserProfile updatedProfile) async {
    if (_currentProfile == null) {
      throw Exception('Aucun profil actif à mettre à jour');
    }

    try {
      // Mettre à jour le profil local
      _currentProfile = updatedProfile;
      
      // Sauvegarder localement
      await _saveProfileLocally(updatedProfile);
      
      // Notifier
      profileChanged.value = updatedProfile;
      
      // Synchroniser avec le cloud si connecté
      if (_authService.isAuthenticated) {
        await _saveProfileToCloud(updatedProfile);
      }
    } catch (e, stack) {
      debugPrint('Exception lors de la mise à jour du profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile update error');
    }
  }
}
