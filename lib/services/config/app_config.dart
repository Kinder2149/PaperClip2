// lib/services/config/app_config.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/api_services.dart';
import '../../models/game_config.dart';
import '../save/save_types.dart';

/// Service de configuration de l'application
/// Remplace FirebaseConfig et FirebaseRemoteConfig
class AppConfig {
  // Instances des services API
  final ConfigService _configService;
  final AnalyticsService _analyticsService;
  
  // Cache des valeurs de configuration
  Map<String, dynamic> _configValues = {};
  
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  
  // Constructeur interne avec injection de dépendances pour les tests
  AppConfig._internal({
    ConfigService? configService,
    AnalyticsService? analyticsService,
  }) : 
    _configService = configService ?? ConfigService(),
    _analyticsService = analyticsService ?? AnalyticsService();
  
  /// Initialise la configuration de l'application
  Future<void> initialize() async {
    try {
      // Valeurs par défaut pour le jeu
      _configValues = {
        'metal_per_paperclip': 0.15,
        'initial_price': 0.25,
        'efficiency_multiplier': 0.10,
        'max_efficiency_level': 8,
      };
      
      // Récupérer la configuration à distance
      await fetchAndActivateConfig();
      debugPrint('Configuration de l\'application initialisée avec succès');
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'initialisation de la configuration: $e');
      _analyticsService.recordError(e, stack, reason: 'Config initialization error');
      
      // Ne pas propager l'erreur pour éviter que l'application ne plante
      // La configuration à distance est optionnelle
    }
  }
  
  /// Récupère et active la configuration à distance
  Future<bool> fetchAndActivateConfig() async {
    try {
      final config = await _configService.getConfig();
      if (config != null && config.isNotEmpty) {
        _configValues.addAll(config);
        return true;
      }
      return false;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération de la configuration: $e');
      _analyticsService.recordError(e, stack, reason: 'Config fetch error');
      return false;
    }
  }
  
  /// Récupère une valeur de configuration
  dynamic getValue(String key) {
    return _configValues[key];
  }
  
  /// Récupère une valeur de configuration de type double
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _configValues[key];
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }
    
    return defaultValue;
  }
  
  /// Récupère une valeur de configuration de type int
  int getInt(String key, {int defaultValue = 0}) {
    final value = _configValues[key];
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }
    
    return defaultValue;
  }
  
  /// Récupère une valeur de configuration de type bool
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _configValues[key];
    if (value == null) return defaultValue;
    
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    
    return defaultValue;
  }
  
  /// Récupère une valeur de configuration de type String
  String getString(String key, {String defaultValue = ''}) {
    final value = _configValues[key];
    if (value == null) return defaultValue;
    
    return value.toString();
  }
  
  /// Sauvegarde une partie dans le cloud
  Future<SaveResult> saveGameToCloud(String userId, String saveData) async {
    try {
      final result = await _configService.saveUserData(userId, 'game_save', saveData);
      return SaveResult(
        success: result.success,
        message: result.message,
        data: result.data,
      );
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde dans le cloud: $e');
      _analyticsService.recordError(e, stack, reason: 'Cloud save error');
      return SaveResult(
        success: false,
        message: 'Erreur lors de la sauvegarde: $e',
      );
    }
  }
  
  /// Charge une partie depuis le cloud
  Future<SaveResult> loadGameFromCloud(String userId) async {
    try {
      final result = await _configService.getUserData(userId, 'game_save');
      return SaveResult(
        success: result.success,
        message: result.message,
        data: result.data,
      );
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement depuis le cloud: $e');
      _analyticsService.recordError(e, stack, reason: 'Cloud load error');
      return SaveResult(
        success: false,
        message: 'Erreur lors du chargement: $e',
      );
    }
  }
  
  /// Charge la configuration du jeu
  Future<GameConfig> loadGameConfig() async {
    try {
      await fetchAndActivateConfig();
      
      return GameConfig(
        metalPerPaperclip: getDouble('metal_per_paperclip', defaultValue: 0.15),
        initialPrice: getDouble('initial_price', defaultValue: 0.25),
        efficiencyMultiplier: getDouble('efficiency_multiplier', defaultValue: 0.10),
        maxEfficiencyLevel: getInt('max_efficiency_level', defaultValue: 8),
      );
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement de la configuration du jeu: $e');
      _analyticsService.recordError(e, stack, reason: 'Game config load error');
      
      // Retourner une configuration par défaut en cas d'erreur
      return GameConfig(
        metalPerPaperclip: 0.15,
        initialPrice: 0.25,
        efficiencyMultiplier: 0.10,
        maxEfficiencyLevel: 8,
      );
    }
  }
}
