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
import '../api/api_client.dart';
// Import du ServiceLocator
import '../../main.dart' show serviceLocator;

class UserManager extends ChangeNotifier {
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
  
  // Rafraîchir l'état d'authentification après une connexion réussie
  Future<void> refreshAuthState() async {
    final isSignedIn = await GamesServicesController().isSignedIn();
    
    if (isSignedIn && _currentProfile == null) {
      // Récupérer les informations du joueur depuis GamesServicesController
      final playerInfo = GamesServicesController().cachedPlayerInfo;
      
      if (playerInfo != null) {
        // Créer ou mettre à jour le profil utilisateur
        _currentProfile = UserProfile(
          userId: playerInfo.id,
          displayName: playerInfo.displayName,
          profileImageUrl: playerInfo.iconImageUrl,
        );
        
        // Notifier les écouteurs
        _profileNotifier.value = _currentProfile;
        profileChanged.value = _currentProfile;
        
        // Authentification avec l'API en utilisant les identifiants Google
        if (_authService != null) {
          try {
            debugPrint('UserManager: Authentification avec Google pour ${playerInfo.id}');
            
            // Utiliser les informations Google pour s'authentifier auprès de notre API
            final result = await _authService!.signInWithGoogle();
            
            if (result) {
              debugPrint('UserManager: Authentification réussie pour l\'utilisateur ${playerInfo.id}');
            } else {
              debugPrint('UserManager: Échec de l\'authentification pour l\'utilisateur ${playerInfo.id}');
              // En cas d'échec, on peut essayer de créer un compte
              if (_authService != null) {
                await _authService!.registerFull(
                  playerInfo.displayName,
                  null, // email (sera récupéré par Google OAuth)
                  null, // password (sera généré côté serveur)
                );
                debugPrint('UserManager: Tentative de création de compte pour ${playerInfo.displayName}');
              }
            }
          } catch (e) {
            debugPrint('UserManager: Erreur lors de l\'authentification API: $e');
          }
        }
        
        // Initialiser les services dépendants de l'authentification
        await _initializeAuthenticatedServices();
      
        // Notifier les écouteurs
        notifyListeners();
        debugPrint('UserManager: Etat d\'authentification mis a jour - Connecte');
      }
    } else if (!isSignedIn && _currentProfile != null) {
      debugPrint('UserManager: Déconnexion détectée, réinitialisation des services');
      
      // Réinitialisation en cas de déconnexion
      _currentProfile = null;
      _profileNotifier.value = null;
      profileChanged.value = null;
      
      // Déconnexion de l'API
      if (_authService != null) {
        try {
          await _authService!.logout();
          debugPrint('UserManager: Déconnexion du compte API réussie');
        } catch (e) {
          debugPrint('UserManager: Erreur lors de la déconnexion API: $e');
          // Même en cas d'erreur, on efface le token local
          final ApiClient apiClient = ApiClient();
          await apiClient.clearAuthToken();
        }
      }
      
      // Réinitialiser les services en mode non authentifié
      try {
        // Réinitialiser tous les services avec userAuthenticated=false
        await updateServices(); // Ceci appellera les services avec userAuthenticated=false
        debugPrint('UserManager: Tous les services réinitialisés en mode non authentifié');
        
        // Effacer les services sociaux secondaires
        _friendsService = null;
        _userStatsService = null;
        
      } catch (e, stack) {
        debugPrint('UserManager: Erreur lors de la réinitialisation des services: $e');
        _analyticsService?.recordError(e, stack, reason: 'Service reset error on logout');
      }
      
      notifyListeners();
      debugPrint('UserManager: Etat d\'authentification mis a jour - Deconnecte');
    }
  }
  
  // Initialiser les services qui nécessitent une authentification
  Future<void> _initializeAuthenticatedServices() async {
    if (_currentProfile == null) {
      debugPrint('UserManager: Impossible d\'initialiser les services authentifiés - Aucun profil utilisateur');
      return;
    }
    
    // Vérifier que nous avons bien un token d'authentification
    final isAuthenticated = _authService?.isAuthenticated ?? false;
    if (!isAuthenticated) {
      debugPrint('UserManager: Impossible d\'initialiser les services authentifiés - Utilisateur non authentifié');
      return;
    }
    
    debugPrint('UserManager: Initialisation des services authentifiés pour ${_currentProfile!.userId}');
    
    try {
      // 1. Réinitialiser tous les services avec userAuthenticated = true
      await updateServices(); // Va appeler les services avec le statut d'authentification correct
      
      // 2. Définir l'ID utilisateur pour l'analytique
      if (_analyticsService != null) {
        _analyticsService!.setUserId(_currentProfile!.userId);
        debugPrint('UserManager: ID utilisateur défini pour AnalyticsService');
      } else {
        debugPrint('UserManager: Impossible de définir l\'ID utilisateur - AnalyticsService manquant');
      }
      
      // 3. Initialiser FriendsService
      if (_socialService != null && _analyticsService != null) {
        _friendsService = FriendsService(
          userId: _currentProfile!.userId,
          userManager: this,
          socialService: _socialService!,
          analyticsService: _analyticsService!,
        );
        debugPrint('UserManager: FriendsService initialisé avec succès');
      } else {
        debugPrint('UserManager: Impossible d\'initialiser FriendsService - Services requis manquants');
      }
      
      // 4. Initialiser UserStatsService
      if (_socialService != null && _analyticsService != null) {
        _userStatsService = UserStatsService(
          userId: _currentProfile!.userId,
          userManager: this,
          socialService: _socialService!,
          analyticsService: _analyticsService!,
        );
        debugPrint('UserManager: UserStatsService initialisé avec succès');
      } else {
        debugPrint('UserManager: Impossible d\'initialiser UserStatsService - Services requis manquants');
      }
      
      // 5. Initialiser d'autres services authentifiés si nécessaire...
      
    } catch (e, stack) {
      debugPrint('UserManager: Erreur lors de l\'initialisation des services authentifiés: $e');
      _analyticsService?.recordError(e, stack, reason: 'Auth services initialization error');
    }
  }

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

      // Vérifier que tous les services requis sont disponibles
      bool servicesMissing = false;
      
      if (_authService == null) {
        debugPrint('Erreur: Service d\'authentification manquant');
        servicesMissing = true;
      }
      
      if (_storageService == null) {
        debugPrint('Erreur: Service de stockage manquant');
        servicesMissing = true;
      }
      
      if (_analyticsService == null) {
        debugPrint('Erreur: Service d\'analytique manquant');
        // Moins critique, continuer sans analytiques
      }
      
      if (_socialService == null) {
        debugPrint('Erreur: Service social manquant');
        // On peut continuer sans service social, mais les fonctionnalités sociales seront désactivées
      }
      
      if (_saveService == null) {
        debugPrint('Erreur: Service de sauvegarde manquant');
        servicesMissing = true;
      }
      
      // Si les services critiques sont manquants, arrêter l'initialisation
      if (servicesMissing) {
        debugPrint('Erreur: Certains services API critiques sont manquants');
        _initialized = true; // Marquer comme initialisé pour éviter des tentatives répétées
        return;
      }
      
      // Initialiser les services sociaux seulement si les services API sont disponibles
      if (_socialService != null && _analyticsService != null) {
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
      }
      
      // Essayer de charger le profil existant s'il y en a un
      await _loadProfileFromLocal();
      
      // Si l'utilisateur est connecté, essayer de charger depuis le serveur
      if (_authService?.isAuthenticated == true && _authService?.userId != null) {
        try {
          await _loadProfileFromServer(_authService!.userId!);
        } catch (e, stackTrace) {
          debugPrint('Erreur lors du chargement du profil depuis le serveur: $e');
          _analyticsService?.recordError(e, stackTrace);
          // Continuer avec le profil local
        }
      }
      
      _initialized = true;
      debugPrint('UserManager initialisé: ${_currentProfile != null ? "Profil trouvé" : "Aucun profil"}');
    } catch (e, stackTrace) {
      debugPrint('Exception lors de l\'initialisation: $e');
      _analyticsService?.recordError(e, stackTrace);
    }
  }

  // Créer un profil utilisateur
  Future<bool> createProfile(String displayName, {bool isOAuthUser = false}) async {
    try {
      // Si l'utilisateur est déjà authentifié via OAuth (Google, Apple, etc.)
      // on ne fait pas d'appel à registerFull car l'utilisateur est déjà créé sur le backend
      String? userId;
      
      if (!isOAuthUser) {
        // Créer un compte sur le backend uniquement si ce n'est pas un utilisateur OAuth
        final result = await _authService!.registerFull(displayName, "", "");
        
        if (result is! Map<String, dynamic> || result['success'] == false) {
          debugPrint('Échec de la création du profil: ${result['message'] ?? 'Erreur inconnue'}');
          return false;
        }
        
        userId = result['user_id'];
      } else {
        // Pour un utilisateur OAuth, on récupère directement l'ID utilisateur de l'AuthService
        debugPrint('Création de profil pour utilisateur OAuth déjà authentifié');
        userId = _authService?.userId;
      }
      
      // Vérifier que nous avons un ID utilisateur valide
      if (userId == null) {
        debugPrint('Impossible de récupérer l\'ID utilisateur');
        return false;
      }
      
      // Créer un profil local
      // Stocker l'information d'administrateur dans les statistiques globales
      final isAdmin = _authService?.isAdmin ?? false;
      
      _currentProfile = UserProfile(
        userId: userId,
        displayName: displayName,
        lastLogin: DateTime.now(),
        globalStats: {
          'lastUpdated': DateTime.now().toIso8601String(),
          'isAdmin': isAdmin,
        },
      );
      
      // Notifier les auditeurs
      _profileNotifier.value = _currentProfile;
      profileChanged.value = _currentProfile;
      
      // Sauvegarder localement
      await _saveProfileToLocal();
      
      // Définir l'ID utilisateur pour l'analytique
      if (_analyticsService != null) {
        await _analyticsService?.setUserId(userId);
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
    if (_currentProfile == null || _analyticsService == null) return;
    
    // Mettre à jour l'ID utilisateur pour l'analytique
    _analyticsService!.setUserId(_currentProfile!.userId);
    
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
  
  // Mettre à jour les services API après l'authentification
  Future<void> updateServices({
    AnalyticsService? analyticsService,
    SocialService? socialService,
    StorageService? storageService,
    SaveService? saveService,
  }) async {
    // Vérifier si l'utilisateur est authentifié
    final bool isAuthenticated = _authService?.isAuthenticated ?? false;
    debugPrint('UserManager: Mise à jour des services (authentifié: $isAuthenticated)');
    
    // Mettre à jour les services fournis ou utiliser ceux existants
    _analyticsService = analyticsService ?? _analyticsService;
    _socialService = socialService ?? _socialService;
    _storageService = storageService ?? _storageService;
    _saveService = saveService ?? _saveService;
    
    // Réinitialiser les services avec le statut d'authentification
    if (_analyticsService != null) {
      await _analyticsService!.initialize(userAuthenticated: isAuthenticated);
      // Mettre à jour l'ID utilisateur si authentifié et profil existant
      if (isAuthenticated && _currentProfile != null) {
        _analyticsService!.setUserId(_currentProfile!.userId);
      }
      debugPrint('UserManager: AnalyticsService réinitialisé (mode ${isAuthenticated ? "authentifié" : "silencieux"})');
    }
    
    if (_storageService != null) {
      await _storageService!.initialize(userAuthenticated: isAuthenticated);
      debugPrint('UserManager: StorageService réinitialisé (mode ${isAuthenticated ? "authentifié" : "hors ligne"})');
    }
    
    if (_socialService != null) {
      await _socialService!.initialize(userAuthenticated: isAuthenticated);
      debugPrint('UserManager: SocialService réinitialisé (mode ${isAuthenticated ? "authentifié" : "simulation"})');
    }
    
    // Réinitialiser les services sociaux secondaires si l'utilisateur est authentifié
    if (isAuthenticated && _socialService != null && _currentProfile != null) {
      _friendsService = FriendsService(
        userId: _currentProfile!.userId,
        userManager: this,
        socialService: _socialService!,
        analyticsService: _analyticsService ?? serviceLocator.analyticsService!
      );
      
      _userStatsService = UserStatsService(
        userId: _currentProfile!.userId,
        userManager: this,
        socialService: _socialService!,
        analyticsService: _analyticsService ?? serviceLocator.analyticsService!
      );
      
      debugPrint('UserManager: Services sociaux secondaires mis à jour');
    } else if (!isAuthenticated) {
      // Effacer les services sociaux secondaires si l'utilisateur n'est pas authentifié
      _friendsService = null;
      _userStatsService = null;
      debugPrint('UserManager: Services sociaux secondaires effacés (utilisateur non authentifié)');
    }
  }
}
