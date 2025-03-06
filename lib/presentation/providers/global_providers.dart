// lib/presentation/providers/global_providers.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/environment_config.dart';
import '../../domain/services/config_service.dart';
import '../../domain/services/logger_service.dart';

class AppStateProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final ConfigService _configService;
  final LoggerService _logger;

  AppStateProvider(this._prefs, this._configService, this._logger);

  // État global de l'application
  bool _isInMaintenanceMode = false;
  bool _isNetworkAvailable = true;
  String _currentEnvironment = EnvironmentConfig.currentEnvironment.name;

  // Getters
  bool get isInMaintenanceMode => _isInMaintenanceMode;
  bool get isNetworkAvailable => _isNetworkAvailable;
  String get currentEnvironment => _currentEnvironment;

  // Méthodes de mise à jour
  void setMaintenanceMode(bool value) {
    _isInMaintenanceMode = value;
    _logger.info('Mode maintenance: $value');
    notifyListeners();
  }

  void setNetworkAvailability(bool value) {
    _isNetworkAvailable = value;
    _logger.info('Disponibilité réseau: $value');
    notifyListeners();
  }

  void changeEnvironment(String environment) {
    if (EnvironmentConfig.Environment.values.any((e) => e.name == environment)) {
      _currentEnvironment = environment;
      _logger.info('Changement d\'environnement: $environment');
      notifyListeners();
    }
  }

  // Vérification des fonctionnalités
  bool isFeatureEnabled(String feature) {
    return _configService.getBoolValue(feature, defaultValue: false);
  }
}

class GameSettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final ConfigService _configService;

  GameSettingsProvider(this._prefs, this._configService);

  // Paramètres du jeu
  bool get soundEnabled => _configService.isSoundEnabled;
  set soundEnabled(bool value) {
    _configService.isSoundEnabled = value;
    notifyListeners();
  }

  bool get musicEnabled => _configService.isMusicEnabled;
  set musicEnabled(bool value) {
    _configService.isMusicEnabled = value;
    notifyListeners();
  }

  bool get notificationsEnabled => _configService.areNotificationsEnabled;
  set notificationsEnabled(bool value) {
    _configService.areNotificationsEnabled = value;
    notifyListeners();
  }

  bool get hardModeEnabled => _configService.hardModeEnabled;
  set hardModeEnabled(bool value) {
    _configService.hardModeEnabled = value;
    notifyListeners();
  }

  // Historique des parties
  List<String> getRecentGames() {
    return _configService.getRecentGames();
  }

  void addRecentGame(String gameName) {
    _configService.addRecentGame(gameName);
    notifyListeners();
  }

  // Réinitialisation des paramètres
  void resetToDefaults() {
    _configService.resetToDefaults();
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}