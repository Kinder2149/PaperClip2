import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:paperclip2/models/game_config.dart';
import 'package:paperclip2/utils/update_manager.dart';
import 'save_strategy.dart';
import 'save_validator.dart';

/// Implémentation de la stratégie de sauvegarde locale utilisant SharedPreferences
class LocalSaveStrategy implements SaveStrategy {
  static const String SAVE_PREFIX = 'paperclip_save_';
  
  /// Obtient la clé de sauvegarde pour un nom donné
  String _getSaveKey(String name) => '$SAVE_PREFIX$name';
  
  @override
  Future<bool> save(String name, Map<String, dynamic> data, {GameMode gameMode = GameMode.INFINITE}) async {
    try {
      // Valider les données
      final validationResult = SaveValidator.validate(data);
      if (!validationResult.isValid) {
        print('Erreur de validation: ${validationResult.errors.join(', ')}');
        return false;
      }
      
      // Préparer les données de sauvegarde
      final saveData = {
        'id': const Uuid().v4(),
        'name': name,
        'timestamp': DateTime.now().toIso8601String(),
        'version': GameConstants.VERSION,
        'gameMode': gameMode.index,
        'gameData': data,
      };
      
      // Sauvegarder dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(name);
      await prefs.setString(key, jsonEncode(saveData));
      
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde locale: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> load(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(name);
      final savedData = prefs.getString(key);
      
      if (savedData == null) {
        return null;
      }
      
      // Décoder les données
      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;
      
      // Vérifier si une migration est nécessaire
      if (UpdateManager.needsMigration(jsonData['version'] as String?)) {
        final migratedData = UpdateManager.migrateData(jsonData);
        return migratedData['gameData'] as Map<String, dynamic>;
      }
      
      return jsonData['gameData'] as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du chargement local: $e');
      return null;
    }
  }
  
  @override
  Future<bool> exists(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(name);
      return prefs.containsKey(key);
    } catch (e) {
      print('Erreur lors de la vérification d\'existence: $e');
      return false;
    }
  }
  
  @override
  Future<bool> delete(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(name);
      return await prefs.remove(key);
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }
  
  @override
  Future<List<SaveInfo>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = <SaveInfo>[];
      
      for (final key in prefs.getKeys()) {
        if (key.startsWith(SAVE_PREFIX)) {
          try {
            final savedData = prefs.getString(key) ?? '{}';
            final data = jsonDecode(savedData) as Map<String, dynamic>;
            
            // Extraire les informations de sauvegarde
            final gameData = data['gameData'] as Map<String, dynamic>?;
            final playerData = gameData?['playerManager'] as Map<String, dynamic>?;
            
            if (playerData != null) {
              saves.add(SaveInfo(
                id: data['id'] as String? ?? key.substring(SAVE_PREFIX.length),
                name: key.substring(SAVE_PREFIX.length),
                timestamp: DateTime.parse(data['timestamp'] as String? ?? DateTime.now().toIso8601String()),
                version: data['version'] as String? ?? GameConstants.VERSION,
                paperclips: (playerData['paperclips'] as num?)?.toDouble() ?? 0.0,
                money: (playerData['money'] as num?)?.toDouble() ?? 0.0,
                isSyncedWithCloud: data['isSyncedWithCloud'] as bool? ?? false,
                cloudId: data['cloudId'] as String?,
                gameMode: data['gameMode'] != null 
                    ? GameMode.values[data['gameMode'] as int] 
                    : GameMode.INFINITE,
              ));
            }
          } catch (e) {
            print('Erreur lors du chargement de la sauvegarde $key: $e');
          }
        }
      }
      
      // Trier par date de sauvegarde (plus récent d'abord)
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      print('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }
} 