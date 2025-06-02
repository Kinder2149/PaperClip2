// lib/services/user/user_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'user_profile.dart';
import '../../models/game_config.dart';
import '../save/save_system.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import '../social/friends_service.dart';
import '../social/user_stats_service.dart';
import '../../models/social/user_stats_model.dart';
import '../../models/game_state.dart';

// Import des services API
import '../api/api_services.dart';
// Import du ServiceLocator
import '../../main.dart' show serviceLocator;

class UserManager {
  // Singleton instance
  static final UserManager instance = UserManager._internal();
  
  // Factory constructor qui renvoie l'instance unique
  factory UserManager({
    AuthService? authService,
    StorageService? storageService,
    AnalyticsService? analyticsService,
    SocialService? socialService,
    SaveService? saveService,
  }) {
    // Initialiser les services de l'instance si fournis
    if (authService != null) instance._authService = authService;
    if (storageService != null) instance._storageService = storageService;
    if (analyticsService != null) instance._analyticsService = analyticsService;
    if (socialService != null) instance._socialService = socialService;
    if (saveService != null) instance._saveService = saveService;
    return instance;
  }
  
  // Constructeur privé pour l'instance singleton
  UserManager._internal()
    : _authService = null,
      _storageService = null,
      _analyticsService = null,
      _socialService = null,
      _saveService = null;

  // Clés pour SharedPreferences
  static const String _userProfileKey = 'user_profile';

  // Services API
  AuthService? _authService;
  StorageService? _storageService;
  AnalyticsService? _analyticsService;
  SocialService? _socialService;
  SaveService? _saveService;
  
  // Accesseurs publics pour les services
  AuthService get authService => _authService!;
  AnalyticsService get analyticsService => _analyticsService!;
  SocialService get socialService => _socialService!;
  SaveService get saveService => _saveService!;
  StorageService get storageService => _storageService!;
  
  // Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _authService?.isAuthenticated ?? false;

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
  final ValueNotifier<UserProfile?> _profileNotifier = ValueNotifier<UserProfile?>(null);

  // Propriétés publiques
  UserProfile? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;
  bool get isInitialized => _initialized;
  FriendsService? get friendsService => _friendsService;
  UserStatsService? get userStatsService => _userStatsService;

  // Setter pour injecter SaveSystem
  void setSaveSystem(SaveSystem saveSystem) {
    _saveSystem = saveSystem;
    debugPrint('UserManager: SaveSystem injecté');
  }

  // Setter pour le contexte
  void setContext(BuildContext context) {
    _context = context;
  }

  // Initialiser le UserManager
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialiser les services API si nécessaire
      _authService ??= serviceLocator.authService;
      _storageService ??= serviceLocator.storageService;
      _analyticsService ??= serviceLocator.analyticsService;
      _socialService ??= serviceLocator.socialService;
      _saveService ??= serviceLocator.saveService;
      
      // Initialiser les services sociaux
      _friendsService = FriendsService(
        userId: currentProfile?.userId ?? '',
        userManager: this,
        socialService: _socialService!,
        analyticsService: _analyticsService!,
      );
      
      _userStatsService = UserStatsService(
        userId: currentProfile?.userId ?? '',
        userManager: this,
        socialService: _socialService!,
        analyticsService: _analyticsService!,
      );
      
      // Essayer de charger le profil localement d'abord
      await _loadProfileFromLocal();
      
      // Si un profil existe déjà dans le cloud, le charger
      if (_authService?.isAuthenticated ?? false) {
        final userId = _authService!.userId;
        if (userId != null) {
          await _loadProfileFromServer(userId);
        }
      }
      
      _initialized = true;
      debugPrint('UserManager: Initialisation terminée');
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de l\'initialisation: $e');
    }
  }

  // Créer un profil utilisateur
  Future<bool> createProfile(String displayName) async {
    try {
      // Créer un compte sur le backend
      final result = await _authService!.registerFull(displayName, "", "");
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec de la création du profil: ${result['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      // Récupérer l'ID utilisateur
      final userId = _authService?.userId;
      if (userId == null) {
        debugPrint('ID utilisateur null après création du compte');
        return false;
      }
      
      // Créer un profil local
      _currentProfile = UserProfile(
        userId: userId,
        displayName: displayName,
      );
      
      // Notifier les auditeurs
      _profileNotifier.value = _currentProfile;
      profileChanged.value = _currentProfile;
      
      // Sauvegarder localement
      await _saveProfileToLocal();
      
      // Définir l'ID utilisateur pour l'analytique
      if (_analyticsService != null) {
        await _analyticsService?.setUserId(_currentProfile!.userId);
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la création du profil: $e');
      return false;
    }
  }

  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      final result = await _authService!.signInWithGoogle();
      
      if (result is! bool || !result) {
        debugPrint('Échec de la connexion avec Google');
        return false;
      }
      
      // Récupérer le profil utilisateur
      final userId = _authService!.userId;
      if (userId == null) {
        debugPrint('ID utilisateur null après connexion Google');
        return false;
      }
      
      await _loadProfileFromServer(userId);
      _notifyExternalServices();
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la connexion Google: $e');
      return false;
    }
  }

  // Lier le profil à un compte Google
  Future<bool> linkProfileToGoogle() async {
    if (_currentProfile == null) return false;
    
    try {
      final result = await _authService!.linkWithGoogle();
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec de la liaison avec Google: ${result['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      // Mettre à jour le profil local si un nouveau profil est retourné
      if (result.containsKey('profile')) {
        _updateProfileObject(result['profile']);
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la liaison avec Google: $e');
      return false;
    }
  }

  // Mettre à jour les statistiques publiques
  Future<bool> updatePublicStats(GameState gameState) async {
    if (_currentProfile == null) return false;
    
    // TODO: Implémenter la mise à jour des statistiques publiques
    // Cette méthode sera implémentée ultérieurement
    
    return true;
  }

  // Télécharger une image de profil
  Future<bool> uploadProfileImage(File? imageFile) async {
    if (_currentProfile == null) return false;
    if (imageFile == null) {
      // Ouvrir le sélecteur d'image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return false;
      imageFile = File(pickedFile.path);
    }
    
    try {
      final result = await _storageService!.uploadProfileImage(
        userId: _currentProfile!.userId,
        imageFile: imageFile,
      );
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec du téléchargement de l\'image de profil');
        return false;
      }
      
      // Mettre à jour l'URL de l'image dans le profil
      final imageUrl = result['url'] as String?;
      if (imageUrl != null) {
        UserProfile updatedProfile = _currentProfile!.copyWith(
          profileImageUrl: imageUrl
        );
        await updateProfileObject(updatedProfile);
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors du téléchargement de l\'image: $e');
      return false;
    }
  }

  // Charger le profil depuis le serveur
  Future<bool> _loadProfileFromServer(String userId) async {
    try {
      final profile = await _authService?.getUserProfile(userId);
      
      if (profile is! Map<String, dynamic>) return false;
      
      if (profile['success'] == false) {
        debugPrint('Échec du chargement du profil: ${profile['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      _currentProfile = UserProfile.fromJson(profile['user'] as Map<String, dynamic>);
      _profileNotifier.value = _currentProfile;
      profileChanged.value = _currentProfile;
      
      await _saveProfileToLocal();
      
      _analyticsService?.logEvent('profile_loaded_from_server');
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors du chargement du profil depuis le serveur: $e');
      return false;
    }
  }

  // Sauvegarder le profil dans le cloud
  Future<bool> _saveProfileToCloud() async {
    if (_currentProfile == null) return false;
    
    try {
      final result = await _authService!.updateProfile(
        _currentProfile!.toJson(),
      );
      
      return result is Map<String, dynamic> && result['success'] == true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la sauvegarde du profil dans le cloud: $e');
      return false;
    }
  }

  // Charger le profil depuis le stockage local
  Future<bool> _loadProfileFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson == null) return false;
      
      final Map<String, dynamic> profileData = json.decode(profileJson);
      _currentProfile = UserProfile.fromJson(profileData);
      _profileNotifier.value = _currentProfile;
      profileChanged.value = _currentProfile;
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors du chargement du profil local: $e');
      return false;
    }
  }

  // Sauvegarder le profil localement
  Future<bool> _saveProfileToLocal() async {
    if (_currentProfile == null) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(_currentProfile!.toJson());
      
      await prefs.setString(_userProfileKey, profileJson);
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la sauvegarde du profil local: $e');
      return false;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateProfile({
    String? displayName,
    String? email,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentProfile == null) return false;
    
    try {
      Map<String, dynamic> updateData = {};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (email != null) updateData['email'] = email;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['profileImageUrl'] = avatarUrl;
      
      final result = await _authService!.updateProfile(updateData);
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec de la mise à jour du profil: ${result['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      // Mettre à jour le profil local
      UserProfile updatedProfile = _currentProfile!.copyWith(
        displayName: displayName,
        profileImageUrl: avatarUrl,
      );
      
      return await updateProfileObject(updatedProfile);
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Mettre à jour l'objet de profil à partir des données JSON
  void _updateProfileObject(Map<String, dynamic> data) {
    if (_currentProfile == null) return;
    
    // Créer un nouveau profil avec les données mises à jour
    UserProfile updatedProfile = _currentProfile!.copyWith(
      displayName: data.containsKey('displayName') ? data['displayName'] : null,
      profileImageUrl: data.containsKey('avatarUrl') ? data['avatarUrl'] : 
                     (data.containsKey('profileImageUrl') ? data['profileImageUrl'] : null),
      globalStats: data.containsKey('globalStats') ? data['globalStats'] : null,
      competitiveSaveIds: data.containsKey('saveIds') ? List<String>.from(data['saveIds']) : null,
    );
    
    _currentProfile = updatedProfile;
    
    // Notifier les auditeurs du changement
    _profileNotifier.value = _currentProfile;
    profileChanged.value = _currentProfile;
  }

  // Ajouter une sauvegarde au profil utilisateur
  Future<bool> addSaveToProfile(String saveId, GameMode mode) async {
    if (_currentProfile == null) return false;
    
    // Convertir GameMode en String pour l'API
    String gameModeStr = mode.toString().split('.').last.toLowerCase();
    
    try {
      final result = await _saveService!.addSaveToProfile(
        saveId,
        gameModeStr,
      );
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec de l\'ajout de la sauvegarde au profil');
        return false;
      }
      
      // Mise à jour du profil local si un nouveau profil est retourné
      if (result.containsKey('profile')) {
        _updateProfileObject(result['profile']);
      } else {
        // Mettre à jour directement
        _currentProfile!.addSaveId(saveId, mode);
        _profileNotifier.value = _currentProfile;
        profileChanged.value = _currentProfile;
        await _saveProfileToLocal();
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Erreur lors de l\'ajout de la sauvegarde: $e');
      return false;
    }
  }

  // Supprimer une sauvegarde du profil utilisateur
  Future<bool> removeSaveFromProfile(String saveId) async {
    if (_currentProfile == null) return false;
    
    try {
      final result = await _saveService!.removeSaveFromProfile(
        saveId,
        deleteFile: true,
      );
      
      if (result is! Map<String, dynamic> || result['success'] == false) {
        debugPrint('Échec de la suppression de la sauvegarde du profil');
        return false;
      }
      
      // Mise à jour du profil local si un nouveau profil est retourné
      if (result.containsKey('profile')) {
        _updateProfileObject(result['profile']);
      } else {
        // Mettre à jour directement
        _currentProfile!.removeSaveId(saveId);
        _profileNotifier.value = _currentProfile;
        profileChanged.value = _currentProfile;
        await _saveProfileToLocal();
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }

  // Mettre à jour les statistiques de l'utilisateur
  Future<bool> updateUserStats(UserStatsModel stats, GameMode mode) async {
    if (_currentProfile == null) return false;
    
    try {
      final result = await _socialService!.updateUserStats(
        userId: _currentProfile!.userId, 
        stats: stats.toJson(),
      );
      
      return result is Map<String, dynamic> && result['success'] == true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      return false;
    }
  }

  // Notifier les services externes des changements
  void _notifyExternalServices() {
    if (_currentProfile == null) return;
    
    // Mettre à jour l'ID utilisateur pour l'analytique
    _analyticsService?.setUserId(_currentProfile!.userId);
    
    // Notifier d'autres services si nécessaire
  }

  // Vérifier si l'utilisateur peut créer une sauvegarde compétitive
  Future<bool> canCreateCompetitiveSave() async {
    if (_currentProfile == null) return false;
    return _currentProfile!.canCreateCompetitiveSave();
  }

  // Synchroniser le profil avec le cloud
  Future<bool> syncWithCloud() async {
    if (_currentProfile == null) return false;
    
    try {
      // Sauvegarder d'abord localement
      await _saveProfileToLocal();
      
      // Puis dans le cloud si connecté
      if (isLoggedIn) {
        return await _saveProfileToCloud();
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la synchronisation: $e');
      return false;
    }
  }

  // Mettre à jour le profil complet
  Future<bool> updateProfileObject(UserProfile updatedProfile) async {
    if (_currentProfile == null) {
      debugPrint('Aucun profil actif pour la mise à jour');
      return false;
    }
    
    try {
      _currentProfile = updatedProfile;
      _profileNotifier.value = updatedProfile;
      profileChanged.value = updatedProfile;
      
      // Sauvegarder localement
      await _saveProfileToLocal();
      
      // Sauvegarder sur le cloud si connecté
      if (isLoggedIn) {
        await _saveProfileToCloud();
      }
      
      return true;
    } catch (e, stackTrace) {
      _analyticsService?.recordError(e, stackTrace);
      debugPrint('Exception lors de la mise à jour du profil: $e');
      return false;
    }
  }
}
