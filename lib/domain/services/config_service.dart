// lib/domain/services/config_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ConfigService {
  final SharedPreferences _prefs;

  ConfigService(this._prefs);

  // Récupération des paramètres généraux
  bool getBoolValue(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  void setBoolValue(String key, bool value) {
    _prefs.setBool(key, value);
  }

  // Gestion des préférences audio
  bool get isSoundEnabled => getBoolValue('sound_enabled', defaultValue: true);
  set isSoundEnabled(bool value) => setBoolValue('sound_enabled', value);

  bool get isMusicEnabled => getBoolValue('music_enabled', defaultValue: true);
  set isMusicEnabled(bool value) => setBoolValue('music_enabled', value);

  // Gestion des notifications
  bool get areNotificationsEnabled => getBoolValue('notifications_enabled', defaultValue: true);
  set areNotificationsEnabled(bool value) => setBoolValue('notifications_enabled', value);

  // Gestion du mode difficile
  bool get hardModeEnabled => getBoolValue('hard_mode', defaultValue: false);
  set hardModeEnabled(bool value) => setBoolValue('hard_mode', value);

  // Récupération de la version actuelle
  String get appVersion => AppConstants.VERSION;

  // Vérification des mises à jour
  bool get hasSeenLatestUpdate =>
      _prefs.getString('last_seen_version') == appVersion;

  void markUpdateAsSeen() {
    _prefs.setString('last_seen_version', appVersion);
  }

  // Gestion des langues
  String getLanguageCode() {
    return _prefs.getString('language_code') ?? 'fr';
  }

  void setLanguageCode(String languageCode) {
    _prefs.setString('language_code', languageCode);
  }

  // Historique des parties
  List<String> getRecentGames() {
    return _prefs.getStringList('recent_games') ?? [];
  }

  void addRecentGame(String gameName) {
    final games = getRecentGames();
    if (!games.contains(gameName)) {
      games.insert(0, gameName);
      if (games.length > 5) games.removeLast(); // Limite à 5 parties récentes
      _prefs.setStringList('recent_games', games);
    }
  }

  // Réinitialisation des paramètres
  void resetToDefaults() {
    _prefs.remove('sound_enabled');
    _prefs.remove('music_enabled');
    _prefs.remove('notifications_enabled');
    _prefs.remove('hard_mode');
  }
}