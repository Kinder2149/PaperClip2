// lib/services/games_services_controller.dart

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import '../main.dart' show serviceLocator;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:games_services/games_services.dart' as gs;
import 'save/save_system.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart' as gs;

import '../services/save/save_types.dart' as save_types;
import '../services/save/storage/cloud_storage_engine.dart';
import '../services/user/google_auth_service.dart';
import '../models/game_config.dart';
import '../models/event_system.dart';
import 'dart:async';

enum CompetitiveAchievement {
  SCORE_10K,
  SCORE_50K,
  SCORE_100K,
  SPEED_RUN,
  EFFICIENCY_MASTER,
}

class GooglePlayerInfo {
  final String id;
  final String displayName;
  final String? iconImageUrl;

  GooglePlayerInfo({
    required this.id,
    required this.displayName,
    this.iconImageUrl,
  });

  // Conversion depuis/vers JSON pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'iconImageUrl': iconImageUrl,
    };
  }

  factory GooglePlayerInfo.fromJson(Map<String, dynamic> json) {
    return GooglePlayerInfo(
      id: json['id'] ?? 'unknown',
      displayName: json['displayName'] ?? 'Joueur',
      iconImageUrl: json['iconImageUrl'],
    );
  }
}

class LeaderboardInfo {
  final int currentScore;
  final int bestScore;
  final int? rank;
  final String leaderboardName;

  LeaderboardInfo({
    required this.currentScore,
    required this.bestScore,
    this.rank,
    required this.leaderboardName,
  });
}

class GamesServicesController extends ChangeNotifier {
  // Vos propriétés Timer existantes
  Timer? _updateTimer;
  Timer? _syncTimer;



  static final GamesServicesController _instance = GamesServicesController._internal();

  // Clés pour SharedPreferences
  static const String _playerInfoKey = 'google_player_info';
  static const String _lastSignInKey = 'last_google_signin';

  // IDs des classements
  static const String generalLeaderboardID = "CgkI-ICryvIBEAIQAg";
  static const String productionLeaderboardID = "CgkI-ICryvIBEAIQAw";
  static const String bankerLeaderboardID = "CgkI-ICryvIBEAIQBA";
  static const String _progressionAchievementId = 'CgkI-ICryvIBEAIQAQ';

  static const String _competitiveScore10kId = 'CgkI-ICryvIBEAIQBQ';
  static const String _competitiveScore50kId = 'CgkI-ICryvIBEAIQBg';
  static const String _competitiveScore100kId = 'CgkI-ICryvIBEAIQBw';
  static const String _competitiveSpeedRunId = 'CgkI-ICryvIBEAIQCA';
  static const String _competitiveEfficiencyId = 'CgkI-ICryvIBEAIQCQ';

  factory GamesServicesController() {
    return _instance;
  }

  GamesServicesController._internal();

  bool _isInitialized = false;
  bool _isSignedIn = false;
  GooglePlayerInfo? _cachedPlayerInfo;
  DateTime? _lastSignInTime;

  // Stream pour notifier des changements de connexion
  final ValueNotifier<bool> signInStatusChanged = ValueNotifier<bool>(false);
  final ValueNotifier<GooglePlayerInfo?> playerInfoChanged = ValueNotifier<GooglePlayerInfo?>(null);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Charger les informations du joueur depuis SharedPreferences
      await _loadCachedPlayerInfo();

      // Si la dernière connexion date de moins de 7 jours, considérer toujours connecté
      if (_lastSignInTime != null &&
          DateTime.now().difference(_lastSignInTime!).inDays < 7 &&
          _cachedPlayerInfo != null) {
        _isSignedIn = true;
        playerInfoChanged.value = _cachedPlayerInfo;
        signInStatusChanged.value = true;
      }

      // Tenter une connexion silencieuse
      try {
        await silentSignIn();
      } catch (e) {
        // Ne pas bloquer l'initialisation en cas d'échec de connexion silencieuse
        debugPrint('Silent sign-in failed: $e');
      }

      _isInitialized = true;
      debugPrint('Games Services initialized');
    } catch (e, stack) {
      debugPrint('Error initializing GameServices: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Connexion silencieuse sans UI
  Future<bool> silentSignIn() async {
    try {
      await GamesServices.signIn();
      final signedIn = await GamesServices.isSignedIn;

      if (signedIn) {
        _isSignedIn = true;

        // Mettre à jour les informations du joueur
        await _fetchAndUpdatePlayerInfo();

        // Notifier
        signInStatusChanged.value = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      // Diagnostic de débogage
      debugPrint("Tentative de connexion à Google Play Games Services");
      debugPrint("Package de l'application: com.kinder2149.paperclip2");
      debugPrint("ID des jeux: 65117274232");

      // Tenter la connexion
      await GamesServices.signIn();
      final signedIn = await GamesServices.isSignedIn;

      if (signedIn) {
        _isSignedIn = true;

        // Mettre à jour les informations du joueur
        await _fetchAndUpdatePlayerInfo();

        // Enregistrer l'heure de connexion
        _lastSignInTime = DateTime.now();
        await _saveLastSignInTime();

        // Notifier les écouteurs
        signInStatusChanged.value = true;

        debugPrint("Connexion aux services de jeu réussie");
        return true;
      } else {
        debugPrint("La connexion n'a pas abouti, mais aucune erreur n'a été lancée");

        // Tenter à nouveau après une courte pause
        await Future.delayed(Duration(seconds: 1));
        await GamesServices.signIn();

        final secondAttempt = await GamesServices.isSignedIn;
        _isSignedIn = secondAttempt;

        if (secondAttempt) {
          // Mettre à jour les informations du joueur
          await _fetchAndUpdatePlayerInfo();

          // Enregistrer l'heure de connexion
          _lastSignInTime = DateTime.now();
          await _saveLastSignInTime();

          // Notifier les écouteurs
          signInStatusChanged.value = true;

          debugPrint("Connexion réussie à la seconde tentative");
          return true;
        }

        debugPrint("Échec même après seconde tentative");
        debugPrint("Vérifiez dans Google Play Console que les empreintes SHA-1 suivantes sont enregistrées:");
        debugPrint("Débogage: 94:95:FD:94:32:6F:9D:6C:1A:64:99:91:9E:41:47:7C:FB:84:F7:54");
        debugPrint("Publication: 98:3F:EC:A7:2B:C0:EA:65:7C:A0:1B:41:EA:CC:C4:1E:C6:B0:42:25");

        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("Erreur explicite lors de la connexion aux services de jeu: $e");
      debugPrint("Stack trace: $stackTrace");

      try {
        serviceLocator.analyticsService?.recordError(e, stackTrace,
            reason: 'Erreur Google Play Games Sign In');
      } catch (_) {
        // Ignorer si l'erreur ne peut pas être enregistrée
      }

      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _isSignedIn = false;
      _cachedPlayerInfo = null;

      // Supprimer les infos stockées localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playerInfoKey);
      await prefs.remove(_lastSignInKey);

      // Notifier
      signInStatusChanged.value = false;
      playerInfoChanged.value = null;

      // Pas de méthode directe pour se déconnecter dans l'API
      debugPrint('Signed out from Google Play Games Services');
    } catch (e, stack) {
      debugPrint('Error signing out: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }



  // Charger une partie depuis le cloud
  Future<String?> loadGameFromCloud(String cloudId) async {
    try {
      // Initialiser le stockage cloud
      final cloudEngine = CloudStorageEngine();
      if (!(await cloudEngine.initialize())) {
        return null;
      }

      // Charger depuis le stockage cloud
      final saveGame = await cloudEngine.load(cloudId);
      if (saveGame == null) {
        return null;
      }

      // Convertir en chaîne JSON
      return jsonEncode(saveGame.toJson());
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement depuis le cloud: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Cloud load error');
      return null;
    }
  }

  static Future<bool> checkSaveExists(String userId) async {
    try {
      // Rediriger vers Cloud Storage
      final authService = GoogleAuthService();
      final accessToken = await authService.getGoogleAccessToken();

      if (accessToken == null) {
        return false;
      }

      // Initialiser Cloud Storage
      final cloudEngine = CloudStorageEngine();
      final initialized = await cloudEngine.initialize();

      if (!initialized) {
        return false;
      }

      // Vérifier si la sauvegarde existe
      final saveGame = await cloudEngine.load(userId);
      return saveGame != null;
    } catch (e) {
      return false;
    }
  }
  // Ajouter ces méthodes dans la classe GamesServicesController
  void _updateSignInStatus(bool isSignedIn) {
    _isSignedIn = isSignedIn;
    notifyListeners();
  }

  Future<bool> saveGameToCloud({String? userId, String? saveData, Object? saveGame}) async {
    try {
      // Cas 1: Sauvegarder à partir d'un objet SaveGame
      if (saveGame != null) {
        // Récupérer les services nécessaires
        final cloudStorageEngine = CloudStorageEngine();

        // Initialiser le stockage cloud
        final initialized = await cloudStorageEngine.initialize();
        if (!initialized) {
          return false;
        }

        // Nous devons créer une nouvelle instance de SaveGame car les types sont incompatibles
        final saveGameToStore = save_types.SaveGame(
          id: 'save_${DateTime.now().millisecondsSinceEpoch}', // Générer un ID unique
          name: 'CloudSave_${DateTime.now().millisecondsSinceEpoch}',
          lastSaveTime: DateTime.now(),
          gameData: {}, // Remplir avec les données appropriées si disponibles
          version: GameConstants.VERSION,
        );

        await cloudStorageEngine.save(saveGameToStore);
        return true;
      }
      // Cas 2: Sauvegarder à partir d'un userId et de données JSON
      else if (userId != null && saveData != null) {
        // Récupérer le service d'authentification
        final authService = GoogleAuthService();
        final accessToken = await authService.getGoogleAccessToken();

        if (accessToken == null) {
          throw Exception('Impossible d\'obtenir un token d\'accès Google');
        }

        // Initialiser le stockage cloud
        final cloudEngine = CloudStorageEngine();
        if (!(await cloudEngine.initialize())) {
          throw Exception('Échec de l\'initialisation du stockage Cloud');
        }

        // Créer un objet SaveGame temporaire pour la sauvegarde
        final saveJson = jsonDecode(saveData) as Map<String, dynamic>;
        final saveGameObj = save_types.SaveGame(
          id: userId, // Utiliser l'ID utilisateur comme ID de sauvegarde
          name: 'save_${DateTime.now().millisecondsSinceEpoch}',
          lastSaveTime: DateTime.now(),
          gameData: saveJson,
          version: GameConstants.VERSION,
        );

        // Sauvegarder dans le cloud
        await cloudEngine.save(saveGameObj);
        return true;
      }

      return false;
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde dans le cloud: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Cloud save error');
      return false;
    }
  }






  // Récupérer la liste des sauvegardes cloud
  Future<List<save_types.SaveGameInfo>> getCloudSaves() async {
    if (!await isSignedIn()) return [];

    try {
      final cloudEngine = CloudStorageEngine();
      // Retourner une liste vide si l'initialisation échoue
      if (!(await cloudEngine.initialize())) {
        return [];
      }

      // Continuer seulement si l'initialisation a réussi
      return await cloudEngine.listSaves();
    } catch (e, stack) {
      debugPrint('Error getting cloud saves: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
      return [];
    }
  }


  // Synchroniser les sauvegardes locales et cloud
  Future<bool> syncSaves() async {
    if (!await isSignedIn()) return false;

    try {
      final saveSystem = SaveSystem();
      await saveSystem.initialize(null);
      return await saveSystem.syncSavesToCloud();
    } catch (e, stack) {
      debugPrint('Error syncing saves: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
      return false;
    }
  }

  // Afficher une interface permettant de sélectionner une sauvegarde
  Future<save_types.SaveGame?> showSaveSelector() async {
    if (!await isSignedIn()) return null;

    try {
      // Récupérer les sauvegardes cloud
      final cloudSaves = await getCloudSaves();

      // Si aucune sauvegarde, retourner null
      if (cloudSaves.isEmpty) return null;

      // Trier les sauvegardes par date (plus récente d'abord)
      cloudSaves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final selectedSave = cloudSaves.first;

      // Charger la sauvegarde sélectionnée
      if (selectedSave.cloudId != null) {
        final jsonStr = await loadGameFromCloud(selectedSave.cloudId!);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          return save_types.SaveGame.fromJson(json);
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('Error showing save selector: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    // Si déjà vérifié comme connecté, utiliser la valeur en cache
    if (_isSignedIn) return true;

    // Sinon, vérifier auprès de l'API
    try {
      final signedIn = await GamesServices.isSignedIn;
      _isSignedIn = signedIn;

      // Si connecté, mais les infos du joueur sont manquantes, les récupérer
      if (signedIn && _cachedPlayerInfo == null) {
        await _fetchAndUpdatePlayerInfo();
      }

      return signedIn;
    } catch (e) {
      debugPrint('Error checking isSignedIn: $e');
      return false;
    }
  }

  Future<void> submitCompetitiveScore({
    required int score,
    required int paperclips,
    required double money,
    required int timePlayed,
    required int level,
    required double efficiency,
  }) async {
    if (!await isSignedIn()) return;

    try {
      // 1. Soumettre le score principal
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: generalLeaderboardID,
            value: score
        ),
      );

      // 2. Soumettre le score de production
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: productionLeaderboardID,
            value: paperclips
        ),
      );

      // 3. Soumettre le score d'argent
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: bankerLeaderboardID,
            value: money.toInt()
        ),
      );

      debugPrint('Competitive scores submitted successfully');
      debugPrint('Score: $score, Paperclips: $paperclips, Money: ${money.toInt()}, Time: $timePlayed, Level: $level, Efficiency: $efficiency');
    } catch (e, stack) {
      debugPrint('Error submitting competitive scores: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Débloquer un succès compétitif
  Future<void> unlockCompetitiveAchievement(
      CompetitiveAchievement achievement) async {
    if (!await isSignedIn()) return;

    try {
      String achievementId;

      // Déterminer l'ID du succès à débloquer
      switch (achievement) {
        case CompetitiveAchievement.SCORE_10K:
          achievementId = _competitiveScore10kId;
          break;
        case CompetitiveAchievement.SCORE_50K:
          achievementId = _competitiveScore50kId;
          break;
        case CompetitiveAchievement.SCORE_100K:
          achievementId = _competitiveScore100kId;
          break;
        case CompetitiveAchievement.SPEED_RUN:
          achievementId = _competitiveSpeedRunId;
          break;
        case CompetitiveAchievement.EFFICIENCY_MASTER:
          achievementId = _competitiveEfficiencyId;
          break;
      }

      // Débloquer le succès
      await GamesServices.unlock(
          achievement: Achievement(
              androidID: achievementId,
              steps: 1
          )
      );

      debugPrint('Competitive achievement unlocked: $achievement');
    } catch (e, stack) {
      debugPrint('Error unlocking competitive achievement: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  Future<void> showCompetitiveLeaderboard() async {
    await showLeaderboard(leaderboardID: generalLeaderboardID);
  }

  Future<void> submitGeneralScore(int paperclips, int money, int playTime) async {
    if (!await isSignedIn()) return;

    try {
      // Score général basé sur les trombones, l'argent et le temps de jeu
      final int score = _calculateGeneralScore(paperclips, money, playTime);

      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: generalLeaderboardID,
            value: score
        ),
      );
      debugPrint('General score submitted: $score');
    } catch (e, stack) {
      debugPrint('Error submitting general score: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Méthode pour soumettre le score de production
  Future<void> submitProductionScore(int paperclips) async {
    if (!await isSignedIn()) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: productionLeaderboardID,
            value: paperclips
        ),
      );
      debugPrint('Production score submitted: $paperclips');
    } catch (e, stack) {
      debugPrint('Error submitting production score: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Méthode pour soumettre le score bancaire
  Future<void> submitBankerScore(int totalMoney) async {
    if (!await isSignedIn()) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: bankerLeaderboardID,
            value: totalMoney
        ),
      );
      debugPrint('Banker score submitted: $totalMoney');
    } catch (e, stack) {
      debugPrint('Error submitting banker score: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Cette méthode est simplifiée car getLeaderboardScores n'existe pas dans la version 4.0.3
  Future<LeaderboardInfo?> getLeaderboardInfo(String leaderboardId, String name) async {
    if (!await isSignedIn()) return null;

    try {
      // Pour l'instant, retourner des valeurs de base
      return LeaderboardInfo(
        currentScore: 0,
        bestScore: 0,
        rank: null,
        leaderboardName: name,
      );
    } catch (e, stack) {
      debugPrint('Error getting leaderboard info: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
      return null;
    }
  }

  Future<double?> getAchievementProgress(String achievementId) async {
    if (!await isSignedIn()) return null;

    try {
      // Dans games_services 4.0.3, loadAchievements retourne AchievementItemList
      final achievements = await GamesServices.loadAchievements();
      if (achievements == null) return 0.0;

      final achievement = achievements.firstWhere(
            (a) => a.id == achievementId,
        orElse: () =>
            AchievementManager.createDefaultAchievement(
              id: achievementId,
            ),
      );

      return achievement.getProgress();
    } catch (e, stack) {
      debugPrint('Error getting achievement progress: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
      return null;
    }
  }

  Future<void> incrementAchievement(LevelSystem levelSystem) async {
    if (!await isSignedIn()) return;

    try {
      final progress = ((levelSystem.level * 10) +
          (levelSystem.experience / levelSystem.experienceForNextLevel * 10))
          .clamp(0, 100).toInt();

      await GamesServices.increment(
          achievement: Achievement(
              androidID: _progressionAchievementId,
              steps: progress
          )
      );
      debugPrint('Achievement progress updated to: $progress%');
    } catch (e, stack) {
      debugPrint('Error updating achievement progress: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Calcul du score général
  int _calculateGeneralScore(int paperclips, int money, int playTime) {
    // Facteurs de pondération
    const int PAPERCLIP_WEIGHT = 1;
    const int MONEY_WEIGHT = 2;
    const int TIME_EFFICIENCY = 1000;

    // Score de base basé sur les trombones et l'argent
    int baseScore = (paperclips * PAPERCLIP_WEIGHT) + (money * MONEY_WEIGHT);

    // Bonus d'efficacité temporelle (plus le temps est court, plus le bonus est grand)
    int timeBonus = playTime > 0 ? (TIME_EFFICIENCY * 1000) ~/ playTime : 0;
    timeBonus = timeBonus.clamp(0, TIME_EFFICIENCY);

    return baseScore + timeBonus;
  }

  // Méthode pour afficher les achievements
  Future<void> showAchievements() async {
    try {
      if (!await isSignedIn()) {
        await signIn();
      }

      await GamesServices.showAchievements();
    } catch (e, stack) {
      debugPrint('Error showing achievements: $e');
      serviceLocator.analyticsService?.recordError(e, stack);
    }
  }

  // Méthode pour afficher les leaderboards
  Future<void> showLeaderboard({required String leaderboardID, bool friendsOnly = false}) async {
    try {
      if (!await isSignedIn()) {
        debugPrint("L'utilisateur n'est pas connecté, tentative de connexion...");
        await signIn();
      }

      // Correction ici - utiliser la syntaxe correcte pour la version 4.0.3
      await GamesServices.showLeaderboards(
        // Utiliser leaderboardID directement, sans le nommer
        androidLeaderboardID: leaderboardID,
        // Si vous avez besoin d'iOS, ajoutez aussi
        // iOSLeaderboardID: leaderboardID,
      );
    } catch (e) {
      debugPrint("Erreur lors de l'affichage du classement: $e");
      await serviceLocator.analyticsService?.recordError(
        e,
        StackTrace.current,
        reason: 'Erreur d\'affichage du classement',
      );
    }
  }

  Future<void> showGeneralLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: generalLeaderboardID);
  }

  // Méthode pour afficher le classement de production
  Future<void> showProductionLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: productionLeaderboardID);
  }

  // Méthode pour afficher le classement bancaire
  Future<void> showBankerLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: bankerLeaderboardID);
  }

  // Méthode pour mettre à jour tous les classements d'un coup
  Future<void> updateAllLeaderboards(GameState gameState) async {
    if (!await isSignedIn()) return;

    try {
      // On utilise catchError pour chaque opération individuelle
      await submitGeneralScore(
          gameState.totalPaperclipsProduced,
          gameState.statistics.getTotalMoneyEarned().toInt(),
          gameState.totalTimePlayed
      ).catchError((e) {
        debugPrint('Error submitting general score: $e');
        return null; // Retourne null mais continue l'exécution
      });

      await submitProductionScore(gameState.totalPaperclipsProduced)
          .catchError((e) {
        debugPrint('Error submitting production score: $e');
        return null;
      });

      await submitBankerScore(
          gameState.statistics.getTotalMoneyEarned().toInt())
          .catchError((e) {
        debugPrint('Error submitting banker score: $e');
        return null;
      });
    } catch (e, stack) {
      // Si une erreur se produit quand même
      debugPrint('Error updating leaderboards: $e');
      serviceLocator.analyticsService?.recordError(e, stack, fatal: false);
    }
  }

  // Récupère les informations du joueur connecté
  Future<GooglePlayerInfo?> getCurrentPlayerInfo() async {
    if (!await isSignedIn()) return null;

    // Si les informations sont déjà en cache, les utiliser
    if (_cachedPlayerInfo != null) {
      return _cachedPlayerInfo;
    }

    // Sinon, tenter de les récupérer
    try {
      await _fetchAndUpdatePlayerInfo();
      return _cachedPlayerInfo;
    } catch (e, stackTrace) {
      debugPrint("Erreur lors de la récupération des infos du joueur: $e");
      serviceLocator.analyticsService?.recordError(e, stackTrace);
      return null;
    }
  }

  // Permet de changer de compte Google
  Future<bool> switchAccount() async {
    try {
      // Déconnecter l'utilisateur actuel
      _isSignedIn = false;
      _cachedPlayerInfo = null;

      // Notifier le changement
      signInStatusChanged.value = false;
      playerInfoChanged.value = null;

      // Attendre un peu pour s'assurer que le changement d'état est pris en compte
      await Future.delayed(Duration(milliseconds: 500));

      // Afficher l'interface de connexion pour permettre à l'utilisateur de choisir un autre compte
      final result = await signIn();

      if (result) {
        debugPrint('Compte changé avec succès');
      } else {
        debugPrint('Échec du changement de compte');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint("Erreur lors du changement de compte: $e");
      serviceLocator.analyticsService?.recordError(e, stackTrace);
      return false;
    }
  }

  // Méthodes privées

  // Récupère les infos du joueur de l'API Google Play Games et les met en cache
  Future<void> _fetchAndUpdatePlayerInfo() async {
    try {
      // Dans l'implémentation actuelle de games_services 4.0.3, il n'y a pas de méthode
      // directe pour obtenir les infos du joueur. Nous allons donc utiliser ce qui est disponible.

      // Obtenir les informations du joueur depuis les achievements
      final achievements = await GamesServices.loadAchievements();
      if (achievements != null && achievements.isNotEmpty) {
        // Essayer d'extraire des infos du premier achievement
        final firstAchievement = achievements.first;

        // Créer un GooglePlayerInfo à partir des informations disponibles
        // Remarque: l'API actuelle ne fournit pas d'ID joueur directement
        // Nous utilisons un ID temporaire basé sur le nom d'utilisateur
        final String playerId = firstAchievement.name.hashCode.toString();
        final String playerName = 'Joueur Google'; // L'API ne fournit pas le nom

        _cachedPlayerInfo = GooglePlayerInfo(
          id: playerId,
          displayName: playerName,
          iconImageUrl: null, // L'API ne fournit pas d'URL d'image
        );

        // Sauvegarder les informations localement
        await _savePlayerInfo();

        // Notifier les écouteurs
        playerInfoChanged.value = _cachedPlayerInfo;

        debugPrint('Informations du joueur mises à jour: ${_cachedPlayerInfo!.displayName}');
      } else {
        debugPrint('Aucune information de joueur disponible');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos du joueur: $e');
    }
  }

  // Sauvegarde les informations du joueur dans SharedPreferences
  Future<void> _savePlayerInfo() async {
    if (_cachedPlayerInfo == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playerInfoKey, jsonEncode(_cachedPlayerInfo!.toJson()));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des infos du joueur: $e');
    }
  }

  // Charge les informations du joueur depuis SharedPreferences
  Future<void> _loadCachedPlayerInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? playerInfoJson = prefs.getString(_playerInfoKey);
      final String? lastSignInTimeStr = prefs.getString(_lastSignInKey);

      if (playerInfoJson != null) {
        _cachedPlayerInfo = GooglePlayerInfo.fromJson(jsonDecode(playerInfoJson));
      }

      if (lastSignInTimeStr != null) {
        _lastSignInTime = DateTime.parse(lastSignInTimeStr);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des infos du joueur: $e');
    }
  }

  // Sauvegarde l'heure de la dernière connexion
  Future<void> _saveLastSignInTime() async {
    if (_lastSignInTime == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSignInKey, _lastSignInTime!.toIso8601String());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la date de connexion: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('GamesServicesController: dispose appelé');

    // Annuler tous les timers
    _updateTimer?.cancel();
    _updateTimer = null;

    _syncTimer?.cancel();
    _syncTimer = null;

    super.dispose();
  }
}
class AchievementManager {
  static AchievementItemData createDefaultAchievement({
    required String id,
    String? customName,
    String? customDescription,
  }) {
    return AchievementItemData(
      id: id,
      name: customName ?? 'Achievement',
      description: customDescription ?? 'Achievement Description',
      completedSteps: 0,
      totalSteps: 100,
      unlocked: false,
    );
  }
}

extension AchievementExtensions on AchievementItemData {
  double getProgress() {
    if (totalSteps <= 0) return unlocked ? 1.0 : 0.0;
    return completedSteps / totalSteps;
  }

  bool isInProgress() {
    return completedSteps > 0 && completedSteps < totalSteps;
  }
}
class SyncResult {
  final bool success;
  final int added;
  final int updated;
  final int conflicts;
  final List<String> errors;

  SyncResult({
    this.success = false,
    this.added = 0,
    this.updated = 0,
    this.conflicts = 0,
    this.errors = const [],
  });
}