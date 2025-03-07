import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../models/game_config.dart';

class FirebaseConfig {
  static final FirebaseConfig _instance = FirebaseConfig._internal();
  static FirebaseConfig get instance => _instance;

  late final FirebaseRemoteConfig _remoteConfig;
  late final FirebaseStorage _storage;
  bool _isInitialized = false;

  FirebaseConfig._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser Firebase
      await Firebase.initializeApp();

      // Configurer Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _configureRemoteConfig();

      // Configurer Storage
      _storage = FirebaseStorage.instance;

      // Configurer Crashlytics
      await _configureCrashlytics();

      _isInitialized = true;
      print('Firebase initialisé avec succès');
    } catch (e, stack) {
      print('Erreur lors de l\'initialisation de Firebase: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<void> _configureRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        'metal_per_paperclip': GameConstants.METAL_PER_PAPERCLIP,
        'initial_money': GameConstants.INITIAL_MONEY,
        'initial_metal': GameConstants.INITIAL_METAL,
        'base_autoclipper_cost': GameConstants.BASE_AUTOCLIPPER_COST,
        'market_volatility': GameConstants.MARKET_VOLATILITY,
        'storage_efficiency_decay': GameConstants.STORAGE_EFFICIENCY_DECAY,
        'competitive_time_limit': GameConstants.COMPETITIVE_TIME_LIMIT.inMinutes,
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      print('Erreur lors de la configuration de Remote Config: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _configureCrashlytics() async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
  }

  // Getters pour les valeurs de Remote Config
  double get metalPerPaperclip => _remoteConfig.getDouble('metal_per_paperclip');
  double get initialMoney => _remoteConfig.getDouble('initial_money');
  double get initialMetal => _remoteConfig.getDouble('initial_metal');
  double get baseAutoclipperCost => _remoteConfig.getDouble('base_autoclipper_cost');
  double get marketVolatility => _remoteConfig.getDouble('market_volatility');
  double get storageEfficiencyDecay => _remoteConfig.getDouble('storage_efficiency_decay');
  int get competitiveTimeLimit => _remoteConfig.getInt('competitive_time_limit');

  // Méthodes de stockage cloud
  Future<void> saveGameToCloud(String userId, Map<String, dynamic> gameData) async {
    try {
      final ref = _storage.ref('saves/$userId/game_save.json');
      final data = jsonEncode(gameData);
      await ref.putString(data, format: PutStringFormat.raw);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<String?> loadGameFromCloud(String userId) async {
    try {
      final ref = _storage.ref('saves/$userId/game_save.json');
      final data = await ref.getData();
      return data != null ? String.fromCharCodes(data) : null;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Future<bool> checkSaveExists(String userId) async {
    try {
      final ref = _storage.ref('saves/$userId/game_save.json');
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteSaveFromCloud(String userId) async {
    try {
      final ref = _storage.ref('saves/$userId/game_save.json');
      await ref.delete();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<List<String>> listCloudSaves(String userId) async {
    try {
      final ref = _storage.ref('saves/$userId');
      final result = await ref.listAll();
      return result.items.map((item) => item.name).toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      return [];
    }
  }

  // Méthodes de gestion des erreurs
  void logError(dynamic error, StackTrace stackTrace, {String? message}) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    } else {
      print('Error: $error');
      print('Stack trace: $stackTrace');
      if (message != null) print('Message: $message');
    }
  }

  void setUserIdentifier(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  void log(String message) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    } else {
      print(message);
    }
  }
} 