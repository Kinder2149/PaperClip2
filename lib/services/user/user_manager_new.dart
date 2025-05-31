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
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;

  // Clés pour SharedPreferences
  static const String _userProfileKey = 'user_profile';

  // Services
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  SaveSystem? _saveSystem;
  
  // Nouveaux services API
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final SocialService _socialService = SocialService();
  final SaveService _saveService = SaveService();

  // État interne
  UserProfile? _currentProfile;
  bool _initialized = false;
  BuildContext? _context;
  FriendsService? _friendsService;
  UserStatsService? _userStatsService;

  // Événements de changement
  final ValueNotifier<UserProfile?> profileChanged = ValueNotifier<UserProfile?>(null);

  // Constructeur interne
  UserManager._internal();

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
      // Initialiser les services API
      await _apiClient.initialize();
      await _authService.initialize();
      await _analyticsService.initialize();
      
      // Charger le profil actuel
      await _loadCurrentProfile();

      // Vérifier la connexion Google
      final isGoogleSignedIn = await _googleAuthService.isUserSignedIn();
      final googleId = await _googleAuthService.getGoogleId();

      if (isGoogleSignedIn && googleId != null) {
        if (_currentProfile != null && _currentProfile!.googleId == null) {
          // Connecté à Google mais profil non lié
          await linkProfileToGoogle();
        } else if (_currentProfile == null) {
          // Connecté à Google mais pas de profil local
          await _loadProfileFromCloud(googleId);
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
      debugPrint('UserManager: initialization terminée avec succès');
    } catch (e, stack) {
      debugPrint('Erreur d\'initialisation UserManager: $e');
      _analyticsService.recordCrash(e, stack, reason: 'UserManager init error');
    }
  }

  // Getters
  UserProfile? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;
  FriendsService? get friendsService => _friendsService;
  UserStatsService? get userStatsService => _userStatsService;

  // Création d'un profil
  Future<UserProfile> createProfile(String displayName) async {
    try {
      // Créer un nouvel ID utilisateur
      final userId = const Uuid().v4();
      
      // Créer le profil
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      // Enregistrer l'utilisateur dans le backend
      await _apiClient.post(
        '/users',
        body: profile.toJson(),
      );
      
      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);
      
      // Initialiser les services sociaux
      _friendsService = FriendsService(userId, this);
      _userStatsService = UserStatsService(userId, this);
      
      // Définir l'ID utilisateur pour l'analytique
      await _analyticsService.setUserId(userId);
      
      // Notifier
      profileChanged.value = profile;
      
      // Log événement
      _analyticsService.logEvent('profile_created', parameters: {
        'user_id': userId,
        'display_name': displayName,
      });
      
      return profile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Profile creation error');
      rethrow;
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
      await _apiClient.put(
        '/users/${_currentProfile!.userId}',
        body: {
          'profile_image_url': imageUrl,
        },
      );
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      return imageUrl;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'upload de l\'image de profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Profile image upload error');
      return null;
    }
  }

  // Création d'un profil avec Google
  Future<UserProfile?> createProfileWithGoogle() async {
    try {
      // Connexion avec Google via le service d'authentification
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        debugPrint('Échec de la connexion avec Google');
        return null;
      }
      
      // Récupérer les informations utilisateur
      final userData = await _apiClient.get('/auth/me');
      
      // Créer ou récupérer le profil
      if (_currentProfile == null) {
        // Créer un nouveau profil
        final profile = UserProfile(
          userId: userData['id'],
          displayName: userData['username'] ?? 'Utilisateur',
          googleId: userData['google_id'],
          profileImageUrl: userData['profile_image_url'],
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        
        // Sauvegarder localement
        _currentProfile = profile;
        await _saveProfileLocally(profile);
        
        // Initialiser les services sociaux
        _friendsService = FriendsService(profile.userId, this);
        _userStatsService = UserStatsService(profile.userId, this);
        
        // Définir l'ID utilisateur pour l'analytique
        await _analyticsService.setUserId(profile.userId);
        
        // Notifier
        profileChanged.value = profile;
        
        // Log événement
        _analyticsService.logEvent('profile_created_with_google', parameters: {
          'user_id': profile.userId,
        });
        
        return profile;
      } else {
        // Mettre à jour le profil existant avec les informations Google
        _currentProfile!.googleId = userData['google_id'];
        _currentProfile!.lastUpdated = DateTime.now();
        
        if (_currentProfile!.profileImageUrl == null && userData['profile_image_url'] != null) {
          _currentProfile!.profileImageUrl = userData['profile_image_url'];
        }
        
        // Sauvegarder localement
        await _saveProfileLocally(_currentProfile!);
        
        // Mettre à jour dans le backend
        await _apiClient.put(
          '/users/${_currentProfile!.userId}',
          body: _currentProfile!.toJson(),
        );
        
        // Notifier
        profileChanged.value = _currentProfile;
        
        // Log événement
        _analyticsService.logEvent('profile_linked_with_google', parameters: {
          'user_id': _currentProfile!.userId,
        });
        
        return _currentProfile;
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil avec Google: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Google profile creation error');
      return null;
    }
  }

  // Lier le profil à Google
  Future<bool> linkProfileToGoogle() async {
    if (_currentProfile == null) return false;

    try {
      // Connexion avec Google via le service d'authentification
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        debugPrint('Échec de la connexion avec Google');
        return false;
      }
      
      // Récupérer les informations Google
      final userData = await _apiClient.get('/auth/me');
      
      // Mettre à jour le profil
      _currentProfile!.googleId = userData['google_id'];
      _currentProfile!.lastUpdated = DateTime.now();
      
      if (_currentProfile!.profileImageUrl == null && userData['profile_image_url'] != null) {
        _currentProfile!.profileImageUrl = userData['profile_image_url'];
      }
      
      // Sauvegarder localement
      await _saveProfileLocally(_currentProfile!);
      
      // Mettre à jour dans le backend
      await _apiClient.put(
        '/users/${_currentProfile!.userId}',
        body: _currentProfile!.toJson(),
      );
      
      // Notifier
      profileChanged.value = _currentProfile;
      
      // Log événement
      _analyticsService.logEvent('profile_linked_with_google', parameters: {
        'user_id': _currentProfile!.userId,
      });
      
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la liaison du profil à Google: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Google profile linking error');
      return false;
    }
  }

  // Chargement du profil depuis le cloud
  Future<UserProfile?> _loadProfileFromCloud(String googleId) async {
    try {
      // Récupérer le profil depuis le backend
      final userData = await _apiClient.get('/users/by-google-id/$googleId');
      
      if (userData == null) {
        debugPrint('Aucun profil trouvé pour l\'ID Google: $googleId');
        return null;
      }
      
      // Créer le profil
      final profile = UserProfile.fromJson(userData);
      
      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);
      
      // Initialiser les services sociaux
      _friendsService = FriendsService(profile.userId, this);
      _userStatsService = UserStatsService(profile.userId, this);
      
      // Définir l'ID utilisateur pour l'analytique
      await _analyticsService.setUserId(profile.userId);
      
      // Notifier
      profileChanged.value = profile;
      
      return profile;
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement du profil depuis le cloud: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Cloud profile loading error');
      return null;
    }
  }

  // Sauvegarde du profil dans le cloud
  Future<void> _saveProfileToCloud(UserProfile profile) async {
    try {
      // Mettre à jour le profil dans le backend
      await _apiClient.put(
        '/users/${profile.userId}',
        body: profile.toJson(),
      );
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde du profil dans le cloud: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Cloud profile saving error');
      rethrow;
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
    if (_currentProfile == null || _context == null) return null;

    try {
      // Sélectionner une image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) {
        debugPrint('Aucune image sélectionnée');
        return null;
      }
      
      // Afficher un indicateur de chargement
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // Upload de l'image
        final imageFile = File(pickedFile.path);
        final imageUrl = await uploadProfileImageFromFile(imageFile);
        
        // Fermer l'indicateur de chargement
        Navigator.of(_context!).pop();
        
        return imageUrl;
      } catch (e) {
        // Fermer l'indicateur de chargement en cas d'erreur
        Navigator.of(_context!).pop();
        rethrow;
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'upload de l\'image de profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Profile image upload error');
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
      // Vérifier si le profil est lié à Google
      if (_currentProfile!.googleId == null) {
        debugPrint('Profil non lié à Google, impossible de synchroniser');
        return false;
      }
      
      // Synchroniser le profil
      await _saveProfileToCloud(_currentProfile!);
      
      // Synchroniser les sauvegardes
      if (_saveSystem != null) {
        final syncSuccess = await _saveService.syncAllSaves();
        debugPrint('Synchronisation cloud complète: profil et sauvegardes');
        return syncSuccess;
      } else {
        debugPrint('SaveSystem non disponible');
        return true; // Le profil a été synchronisé même si les sauvegardes ne l'ont pas été
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la synchronisation avec le cloud: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Cloud sync error');
      return false;
    }
  }

  // Vérifier si une partie compétitive peut être créée
  Future<bool> canCreateCompetitiveSave() async {
    await initialize(); // S'assurer que UserManager est initialisé
    return _currentProfile == null || _currentProfile!.canCreateCompetitiveSave();
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
      // Mettre à jour les statistiques
      _currentProfile!.updateGlobalStats(newStats);
      
      // Sauvegarder
      await _saveProfileLocally(_currentProfile!);
      
      if (_currentProfile!.googleId != null) {
        await _saveProfileToCloud(_currentProfile!);
      }
      
      // Mettre à jour les statistiques dans le backend
      await _socialService.updateUserStats(newStats);
      
      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Stats update error');
    }
  }

  // Mise à jour du profil
  Future<void> updateProfile(UserProfile updatedProfile) async {
    if (_currentProfile == null) {
      throw Exception('Aucun profil actif à mettre à jour');
    }

    try {
      // Sauvegarder localement
      _currentProfile = updatedProfile;
      await _saveProfileLocally(updatedProfile);
      
      // Notifier
      profileChanged.value = updatedProfile;
      
      // Sauvegarder dans le cloud si connecté
      if (updatedProfile.googleId != null) {
        await _saveProfileToCloud(updatedProfile);
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Profile update error');
      rethrow;
    }
  }
}
