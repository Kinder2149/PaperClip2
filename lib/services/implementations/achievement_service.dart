import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_achievement_service.dart';

class AchievementService implements IAchievementService {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  static const String _achievementPrefix = 'achievement_';
  static const String _progressPrefix = 'progress_';
  static const String _userId = 'local_user'; // À remplacer par l'ID réel de l'utilisateur

  AchievementService(this._prefs) : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    try {
      await _syncAchievements();
    } catch (e) {
      print('Erreur lors de l\'initialisation des succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> unlockAchievement(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('L\'ID du succès ne peut pas être vide');
    }

    try {
      final key = _achievementPrefix + id;
      await _prefs.setBool(key, true);
      await _syncAchievementToCloud(id, true);
    } catch (e) {
      print('Erreur lors du débloquage du succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> incrementAchievement(String id, int value) async {
    if (id.isEmpty) {
      throw ArgumentError('L\'ID du succès ne peut pas être vide');
    }
    if (value < 0) {
      throw ArgumentError('La valeur d\'incrémentation doit être positive');
    }

    try {
      final key = _progressPrefix + id;
      final currentProgress = _prefs.getInt(key) ?? 0;
      await _prefs.setInt(key, currentProgress + value);
      await _syncProgressToCloud(id, currentProgress + value);
    } catch (e) {
      print('Erreur lors de l\'incrémentation du succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> showAchievements() async {
    try {
      final achievements = await _getAllAchievements();
      // TODO: Implémenter l'affichage des succès dans l'UI
      print('Achievements: $achievements');
    } catch (e) {
      print('Erreur lors de l\'affichage des succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncAchievements() async {
    try {
      final achievements = await _getAllAchievements();
      for (final achievement in achievements.entries) {
        await _syncAchievementToCloud(achievement.key, achievement.value);
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des succès: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAchievementUnlocked(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('L\'ID du succès ne peut pas être vide');
    }

    try {
      final key = _achievementPrefix + id;
      return _prefs.getBool(key) ?? false;
    } catch (e) {
      print('Erreur lors de la vérification du succès: $e');
      rethrow;
    }
  }

  @override
  Future<int> getAchievementProgress(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('L\'ID du succès ne peut pas être vide');
    }

    try {
      final key = _progressPrefix + id;
      return _prefs.getInt(key) ?? 0;
    } catch (e) {
      print('Erreur lors de la récupération de la progression: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetAchievements() async {
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_achievementPrefix) || key.startsWith(_progressPrefix)) {
          await _prefs.remove(key);
        }
      }
      await _resetCloudAchievements();
    } catch (e) {
      print('Erreur lors de la réinitialisation des succès: $e');
      rethrow;
    }
  }

  Future<Map<String, bool>> _getAllAchievements() async {
    try {
      final keys = _prefs.getKeys();
      final achievements = <String, bool>{};
      for (final key in keys) {
        if (key.startsWith(_achievementPrefix)) {
          final id = key.substring(_achievementPrefix.length);
          achievements[id] = _prefs.getBool(key) ?? false;
        }
      }
      return achievements;
    } catch (e) {
      print('Erreur lors de la récupération de tous les succès: $e');
      rethrow;
    }
  }

  Future<void> _syncAchievementToCloud(String id, bool unlocked) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievements')
          .doc(id)
          .set({
        'unlocked': unlocked,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la synchronisation du succès vers le cloud: $e');
      rethrow;
    }
  }

  Future<void> _syncProgressToCloud(String id, int progress) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievement_progress')
          .doc(id)
          .set({
        'progress': progress,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la synchronisation de la progression vers le cloud: $e');
      rethrow;
    }
  }

  Future<void> _resetCloudAchievements() async {
    try {
      final batch = _firestore.batch();
      final achievementsRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievements');
      final progressRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievement_progress');

      final achievements = await achievementsRef.get();
      final progress = await progressRef.get();

      for (final doc in achievements.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in progress.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la réinitialisation des succès dans le cloud: $e');
      rethrow;
    }
  }
} 