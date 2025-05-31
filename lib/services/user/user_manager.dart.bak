// lib/services/user/user_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;

  // Clés pour SharedPreferences
  static const String _userProfileKey = 'user_profile';

  // Services
  final GoogleAuthService _authService = GoogleAuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  SaveSystem? _saveSystem;

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
  // lib/services/user/user_manager.dart

// Modifier la méthode d'initialisation
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Charger le profil actuel
      await _loadCurrentProfile();

      // Vérifier la connexion Google
      final isGoogleSignedIn = await _authService.isUserSignedIn();
      final googleId = await _authService.getGoogleId();

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
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'UserManager init error');
    }
  }

  // Getters
  UserProfile? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;
  FriendsService? get friendsService => _friendsService;
  UserStatsService? get userStatsService => _userStatsService;

  // Création d'un profil
  Future<UserProfile> createProfile(String displayName) async {
    // Vérifier si l'utilisateur est authentifié auprès de Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? firebaseUid = firebaseUser?.uid;
    // Générer un nouvel ID ou utiliser l'UID Firebase
    final String userId = firebaseUid ?? const Uuid().v4();

    // Si un profil existe déjà et que nous ne voulons pas l'écraser, lancer une exception
    // Mais vous pouvez également choisir de le mettre à jour
    if (_currentProfile != null) {
      debugPrint('Un profil existe déjà, mise à jour...');
      // Option 1: Lancer une exception
      // throw Exception('Un profil existe déjà');

      // Option 2: Mettre à jour le profil existant
      final updatedProfile = _currentProfile!.copyWith(
        displayName: displayName,
      );

      // Sauvegarder les modifications
      await updateProfile(updatedProfile);
      return updatedProfile;
    }

    try {
      // Générer un ID unique
      final userId = const Uuid().v4();

      // Récupérer l'ID Google si connecté (mais ne pas échouer si pas disponible)
      String? googleId;
      try {
        googleId = await _authService.getGoogleId();
      } catch (e) {
        debugPrint('Impossible de récupérer l\'ID Google: $e');
        // Continuer sans ID Google
      }

      // Créer le profil
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        googleId: firebaseUid,
      );

      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);

      // Sauvegarder dans le cloud si connecté à Google (mais ne pas échouer si pas possible)
      if (googleId != null) {
        try {
          await _saveProfileToCloud(profile);
        } catch (e) {
          debugPrint('Erreur lors de la sauvegarde cloud du profil: $e');
          // Continuer malgré l'erreur cloud
        }
      }

      // Sauvegarder dans Firestore pour lier explicitement
      if (firebaseUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUid)
            .set({
          'profileId': userId,
          'displayName': displayName,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Notifier les changements
      profileChanged.value = profile;
      debugPrint('Profil local créé avec succès: ${profile.displayName}');

      return profile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile creation error');
      rethrow;
    }
  }

  // Ajoutez cette méthode pour mettre à jour les statistiques:
  Future<bool> updatePublicStats(GameState gameState) async {
    if (_userStatsService == null || _currentProfile == null) {
      return false;
    }

    return await _userStatsService!.updatePublicStats(gameState);
  }


  Future<void> uploadProfileImageFromFile(File imageFile) async {
    if (_currentProfile == null) {
      throw Exception('Aucun profil actif');
    }

    try {
      // Sauvegarder localement
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile_${_currentProfile!.userId}.jpg';

      final localImage = File(filePath);
      await localImage.writeAsBytes(await imageFile.readAsBytes());

      // Mettre à jour le profil
      final updatedProfile = _currentProfile!.copyWith(
        profileImagePath: filePath,
        customAvatarPath: null, // Réinitialiser l'avatar prédéfini s'il y en avait un
      );

      // Télécharger sur Firebase si connecté à Google
      if (updatedProfile.googleId != null) {
        final storageRef = _storage.ref().child('profiles/${updatedProfile.userId}/profile.jpg');
        await storageRef.putFile(localImage);
        final downloadUrl = await storageRef.getDownloadURL();

        updatedProfile.updateProfileImageUrl(downloadUrl);
      }

      // Sauvegarder
      _currentProfile = updatedProfile;
      await _saveProfileLocally(updatedProfile);

      if (updatedProfile.googleId != null) {
        await _saveProfileToCloud(updatedProfile);
      }

      // Notifier
      profileChanged.value = updatedProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile image upload error');
      rethrow;
    }
  }

  // Création d'un profil avec Google
  Future<bool> createProfileWithGoogle() async {
    try {
      // Se connecter en utilisant le service d'authentification existant
      final googleInfo = await _authService.signInWithGoogle();

      if (googleInfo == null) {
        debugPrint('Erreur: Aucune information Google retournée');
        return false;
      }

      // Créer un profil avec les informations Google
      final profile = UserProfile(
        userId: const Uuid().v4(),
        displayName: googleInfo['displayName'] ?? 'Joueur Google',
        googleId: googleInfo['id'],
        profileImageUrl: googleInfo['photoUrl'],
      );

      // Une fois le profil créé, initialiser les services sociaux
      if (_currentProfile != null) {
        _friendsService = FriendsService(_currentProfile!.userId, this);
        _userStatsService = UserStatsService(_currentProfile!.userId, this);
      }

      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);

      // Sauvegarder dans le cloud - avec gestion d'erreur et l'opérateur ?.
      try {
        await _saveSystem?.syncSavesToCloud();
      } catch (cloudError) {
        debugPrint('Avertissement: Erreur lors de la sauvegarde cloud, mais le profil local a été créé: $cloudError');
        // On continue malgré l'erreur cloud
      }

      // Notifier les changements
      profileChanged.value = profile;
      debugPrint('Profil Google créé avec succès: ${profile.displayName}');

      return true;
    } catch (e, stack) {
      debugPrint('Erreur détaillée lors de la création du profil Google: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google profile creation error');
      return false;
    }
  }

  // Lier un profil local à Google
  Future<void> linkProfileToGoogle() async {
    if (_currentProfile == null) {
      throw Exception('Aucun profil à lier');
    }

    try {
      debugPrint('Tentative de liaison avec Google Play Games...');

      // Utiliser le service d'authentification existant plutôt que de créer une nouvelle instance
      final googleInfo = await _authService.signInWithGoogle();

      if (googleInfo == null) {
        debugPrint('Échec : Aucune information Google obtenue');
        throw Exception('Échec de la connexion Google');
      }

      debugPrint('Infos Google obtenues: ID=${googleInfo['id']}, Nom=${googleInfo['displayName']}');

      // Mettre à jour le profil
      final updatedProfile = _currentProfile!.copyWith(
        googleId: googleInfo['id'],
        displayName: _currentProfile!.displayName.isEmpty ?
        googleInfo['displayName'] :
        _currentProfile!.displayName,
        profileImageUrl: _currentProfile!.profileImageUrl ?? googleInfo['photoUrl'],
      );

      // Sauvegarder localement
      debugPrint('Mise à jour du profil local avec les infos Google');
      _currentProfile = updatedProfile;
      await _saveProfileLocally(updatedProfile);

      // Sauvegarder dans le cloud via SaveSystem si disponible (avec l'opérateur ?.)
      try {
        debugPrint('Tentative de sauvegarde via SaveSystem...');
        await _saveSystem?.syncSavesToCloud();
      } catch (cloudError) {
        debugPrint('Avertissement: Erreur lors de la sauvegarde cloud, mais le profil local a été mis à jour: $cloudError');
        // On continue malgré l'erreur cloud
      }

      // Notifier des changements
      profileChanged.value = updatedProfile;
      debugPrint('Liaison avec Google réussie');
    } catch (e, stack) {
      debugPrint('Erreur détaillée lors de la liaison au compte Google: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google link error');
      rethrow;
    }
  }

  // Charger un profil depuis le cloud
  Future<void> _loadProfileFromCloud(String googleId) async {
    try {
      // Récupérer le profil depuis Firebase Storage
      final storageRef = _storage.ref().child('profiles/$googleId/profile.json');
      final downloadUrl = await storageRef.getDownloadURL();

      // Télécharger et lire le contenu
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(json);

        // Mettre à jour le profil local
        _currentProfile = profile;
        _currentProfile!.updateLastLogin();
        await _saveProfileLocally(profile);
        profileChanged.value = profile;
      }
    } catch (e) {
      debugPrint('Profil non trouvé dans le cloud: $e');
      // C'est normal si le profil n'existe pas encore
    }
  }

  // Sauvegarder le profil dans le cloud
  Future<void> _saveProfileToCloud(UserProfile profile) async {
    if (profile.googleId == null) return;

    try {
      // Déléguer la sauvegarde cloud au SaveSystem si disponible
      if (_saveSystem != null) {
        await _saveSystem!.syncSavesToCloud();
        debugPrint('Profil synchronisé avec le cloud via SaveSystem');
      } else {
        debugPrint('SaveSystem non disponible, sauvegarde locale uniquement');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde cloud du profil: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile cloud save error');
      // Ne pas propager l'erreur
    }
  }

  // Charger le profil local
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson != null) {
        _currentProfile = UserProfile.fromJson(jsonDecode(profileJson));
        _currentProfile!.updateLastLogin();
        await _saveProfileLocally(_currentProfile!);
        profileChanged.value = _currentProfile;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      _currentProfile = null;
    }
  }

  // Sauvegarder le profil localement
  Future<void> _saveProfileLocally(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde locale du profil: $e');
    }
  }

  // Télécharger une photo de profil
  Future<void> uploadProfileImage() async {
    if (_currentProfile == null) {
      throw Exception('Aucun profil actif');
    }

    try {
      // Sélectionner une image
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // Sauvegarder localement
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile_${_currentProfile!.userId}.jpg';

      final localImage = File(filePath);
      await localImage.writeAsBytes(await image.readAsBytes());

      // Mettre à jour le profil
      final updatedProfile = _currentProfile!.copyWith(
        profileImagePath: filePath,
      );

      // Télécharger sur Firebase si connecté à Google
      if (updatedProfile.googleId != null) {
        final storageRef = _storage.ref().child('profiles/${updatedProfile.userId}/profile.jpg');
        await storageRef.putFile(localImage);
        final downloadUrl = await storageRef.getDownloadURL();

        updatedProfile.updateProfileImageUrl(downloadUrl);
      }

      // Sauvegarder
      _currentProfile = updatedProfile;
      await _saveProfileLocally(updatedProfile);

      if (updatedProfile.googleId != null) {
        await _saveProfileToCloud(updatedProfile);
      }

      // Notifier
      profileChanged.value = updatedProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile image upload error');
      rethrow;
    }
  }

  // Ajouter une sauvegarde au profil
  Future<void> addSaveToProfile(String saveId, GameMode mode) async {
    if (_currentProfile == null) return;

    try {
      // Ajouter l'ID de sauvegarde
      _currentProfile!.addSaveId(saveId, mode);

      // Sauvegarder
      await _saveProfileLocally(_currentProfile!);

      if (_currentProfile!.googleId != null) {
        await _saveProfileToCloud(_currentProfile!);
      }

      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'ajout de la sauvegarde au profil: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Add save error');
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
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Remove save error');
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

      // Synchroniser avec SaveSystem si disponible
      if (_saveSystem != null) {
        final syncSuccess = await _saveSystem!.syncSavesToCloud();
        debugPrint('Synchronisation cloud complète: profil et sauvegardes');
        return syncSuccess;
      } else {
        debugPrint('SaveSystem non disponible');
        return false;
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la synchronisation avec le cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Cloud sync error');
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

      // Notifier
      profileChanged.value = _currentProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Stats update error');
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
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile update error');
      rethrow;
    }
  }
}