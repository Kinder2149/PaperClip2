import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service pour tracker la dernière entreprise jouée par l'utilisateur.
/// Permet le smart routing au démarrage de l'application.
class LastPlayedTracker {
  static const String _keyEnterpriseId = 'last_played_enterprise_id';
  static const String _keyTimestamp = 'last_played_at';

  static LastPlayedTracker? _instance;
  static LastPlayedTracker get instance {
    _instance ??= LastPlayedTracker._();
    return _instance!;
  }

  LastPlayedTracker._();

  /// Enregistre la dernière entreprise jouée
  Future<void> setLastPlayed(String enterpriseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEnterpriseId, enterpriseId);
      await prefs.setString(_keyTimestamp, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        print('[LastPlayedTracker] Dernière entreprise enregistrée: $enterpriseId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LastPlayedTracker] Erreur lors de l\'enregistrement: $e');
      }
    }
  }

  /// Récupère l'ID de la dernière entreprise jouée
  Future<String?> getLastPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enterpriseId = prefs.getString(_keyEnterpriseId);
      
      if (kDebugMode && enterpriseId != null) {
        print('[LastPlayedTracker] Dernière entreprise récupérée: $enterpriseId');
      }
      
      return enterpriseId;
    } catch (e) {
      if (kDebugMode) {
        print('[LastPlayedTracker] Erreur lors de la récupération: $e');
      }
      return null;
    }
  }

  /// Récupère le timestamp de la dernière session
  Future<DateTime?> getLastPlayedTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_keyTimestamp);
      
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[LastPlayedTracker] Erreur lors de la récupération du timestamp: $e');
      }
      return null;
    }
  }

  /// Efface les données de la dernière entreprise jouée
  Future<void> clearLastPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyEnterpriseId);
      await prefs.remove(_keyTimestamp);
      
      if (kDebugMode) {
        print('[LastPlayedTracker] Données effacées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LastPlayedTracker] Erreur lors de l\'effacement: $e');
      }
    }
  }
}
