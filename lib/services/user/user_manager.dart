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

import 'user_profile.dart';
import 'google_auth_service.dart';
import '../../models/game_config.dart';
import '../save/save_system.dart';

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

  // Création d'un profil
  Future<UserProfile> createProfile(String displayName) async {
    if (_currentProfile != null) {
      throw Exception('Un profil existe déjà');
    }

    try {
      // Générer un ID unique
      final userId = const Uuid().v4();

      // Récupérer l'ID Google si connecté
      String? googleId;
      try {
        googleId = await _authService.getGoogleId();
      } catch (e) {
        debugPrint('Impossible de récupérer l\'ID Google: $e');
      }

      // Créer le profil
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        googleId: googleId,
      );

      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);

      // Sauvegarder dans le cloud si connecté à Google
      if (googleId != null) {
        await _saveProfileToCloud(profile);
      }

      // Notifier les changements
      profileChanged.value = profile;

      return profile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile creation error');
      rethrow;
    }
  }

  // Création d'un profil avec Google
  Future<bool> createProfileWithGoogle() async {
    try {
      // Se connecter à Google
      final googleInfo = await _authService.signInWithGoogle();

      if (googleInfo == null) {
        throw Exception('Échec de la connexion Google');
      }

      // Créer un profil avec les informations Google
      final profile = UserProfile(
        userId: const Uuid().v4(),
        displayName: googleInfo['displayName'] ?? 'Joueur Google',
        googleId: googleInfo['id'],
        profileImageUrl: googleInfo['photoUrl'],
      );

      // Sauvegarder localement
      _currentProfile = profile;
      await _saveProfileLocally(profile);

      // Sauvegarder dans le cloud
      await _saveProfileToCloud(profile);

      // Notifier les changements
      profileChanged.value = profile;

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la création du profil Google: $e');
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
      // Se connecter à Google
      final googleInfo = await _authService.getGoogleProfileInfo() ??
          await _authService.signInWithGoogle();

      if (googleInfo == null) {
        throw Exception('Échec de la connexion Google');
      }

      // Mettre à jour le profil
      final updatedProfile = _currentProfile!.copyWith(
        googleId: googleInfo['id'],
        displayName: _currentProfile!.displayName.isEmpty ?
        googleInfo['displayName'] :
        _currentProfile!.displayName,
        profileImageUrl: _currentProfile!.profileImageUrl ?? googleInfo['photoUrl'],
      );

      // Sauvegarder
      _currentProfile = updatedProfile;
      await _saveProfileLocally(updatedProfile);
      await _saveProfileToCloud(updatedProfile);

      // Notifier
      profileChanged.value = updatedProfile;
    } catch (e, stack) {
      debugPrint('Erreur lors de la liaison au compte Google: $e');
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
      // Convertir en JSON
      final profileJson = jsonEncode(profile.toJson());
      final bytes = utf8.encode(profileJson);

      // Créer directement la référence du fichier
      final storageRef = _storage.ref().child('profiles/${profile.googleId}/profile.json');

      // Utiliser putData avec les métadonnées pour s'assurer que le type de contenu est correct
      final metadata = SettableMetadata(
        contentType: 'application/json',
        customMetadata: {'createdBy': 'UserManager', 'version': GameConstants.VERSION},
      );

      await storageRef.putData(bytes, metadata);

      debugPrint('Profil sauvegardé avec succès dans le cloud pour l\'utilisateur ${profile.googleId}');
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde cloud du profil: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile cloud save error');

      // Ne pas propager l'erreur, pour éviter de perturber le flux de l'application
      // car la sauvegarde cloud est optionnelle
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

      // 1. Sauvegarder le profil dans le cloud
      await _saveProfileToCloud(_currentProfile!);

      // 2. Synchroniser les sauvegardes si SaveSystem est disponible
      if (_saveSystem != null) {
        final syncSuccess = await _saveSystem!.syncSavesToCloud();
        if (!syncSuccess) {
          debugPrint('Échec de la synchronisation des sauvegardes, mais profil synchronisé');
          return false;
        }
      } else {
        debugPrint('SaveSystem non disponible, seul le profil a été synchronisé');
        return false;
      }

      debugPrint('Synchronisation cloud complète: profil et sauvegardes');
      return true;
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