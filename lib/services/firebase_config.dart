import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/game_config.dart';

class FirebaseConfig {
  static final FirebaseConfig _instance = FirebaseConfig._internal();
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  factory FirebaseConfig() {
    return _instance;
  }

  FirebaseConfig._internal();

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await _setupRemoteConfig();
      await _setupCrashlytics();
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'initialisation de Firebase: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _setupRemoteConfig() async {
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.setDefaults({
        'game_version': GameConstants.VERSION,
        'max_storage': 1000000,
        'max_production': 100000,
        'market_update_interval': 300,
        'crisis_probability': 0.1,
        'xp_multiplier': 1.0,
      });

      await remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      debugPrint('Erreur lors de la configuration de Remote Config: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _setupCrashlytics() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  Future<void> saveGameToCloud(String userId, Map<String, dynamic> gameData) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      final data = jsonEncode(gameData);
      await ref.putString(data);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loadGameFromCloud(String userId) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      final data = await ref.getData();
      if (data == null) return null;
      return jsonDecode(String.fromCharCodes(data)) as Map<String, dynamic>;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Future<bool> checkSaveExists(String userId) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  double getMarketUpdateInterval() {
    return remoteConfig.getDouble('market_update_interval');
  }

  double getCrisisProbability() {
    return remoteConfig.getDouble('crisis_probability');
  }

  double getXPMultiplier() {
    return remoteConfig.getDouble('xp_multiplier');
  }

  int getMaxStorage() {
    return remoteConfig.getInt('max_storage');
  }

  int getMaxProduction() {
    return remoteConfig.getInt('max_production');
  }

  String getGameVersion() {
    return remoteConfig.getString('game_version');
  }
} 