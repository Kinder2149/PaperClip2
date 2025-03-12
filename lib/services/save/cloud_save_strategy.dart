import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:paperclip2/models/game_config.dart';
import 'save_strategy.dart';
import 'save_validator.dart';

/// Implémentation de la stratégie de sauvegarde cloud utilisant Firebase Storage
class CloudSaveStrategy implements SaveStrategy {
  static const String SAVE_PREFIX = 'paperclip_save_';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Obtient l'ID de l'utilisateur actuel
  String? get _userId => _auth.currentUser?.uid;
  
  /// Vérifie si l'utilisateur est connecté
  bool get _isSignedIn => _auth.currentUser != null;
  
  /// Obtient la référence de stockage pour une sauvegarde
  Reference _getSaveRef(String name) {
    if (_userId == null) {
      throw SaveError('AUTH_ERROR', 'Utilisateur non connecté');
    }
    return _storage.ref('saves/$_userId/$SAVE_PREFIX$name.json');
  }
  
  @override
  Future<bool> save(String name, Map<String, dynamic> data, {GameMode gameMode = GameMode.INFINITE}) async {
    try {
      if (!_isSignedIn) {
        debugPrint('Utilisateur non connecté à Firebase');
        return false;
      }
      
      // Valider les données
      final validationResult = SaveValidator.validate(data);
      if (!validationResult.isValid) {
        debugPrint('Erreur de validation: ${validationResult.errors.join(', ')}');
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
      
      // Convertir en JSON
      final jsonData = jsonEncode(saveData);
      
      // Sauvegarder dans Firebase Storage
      final ref = _getSaveRef(name);
      await ref.putString(
        jsonData,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(
          contentType: 'application/json',
          customMetadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'gameMode': gameMode.toString(),
          },
        ),
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde cloud: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> load(String name) async {
    try {
      if (!_isSignedIn) {
        debugPrint('Utilisateur non connecté à Firebase');
        return null;
      }
      
      // Récupérer les données depuis Firebase Storage
      final ref = _getSaveRef(name);
      final data = await ref.getData();
      
      if (data == null) {
        return null;
      }
      
      // Décoder les données
      final jsonString = utf8.decode(data);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return jsonData['gameData'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erreur lors du chargement cloud: $e');
      return null;
    }
  }
  
  @override
  Future<bool> exists(String name) async {
    try {
      if (!_isSignedIn) {
        return false;
      }
      
      final ref = _getSaveRef(name);
      try {
        await ref.getMetadata();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'existence: $e');
      return false;
    }
  }
  
  @override
  Future<bool> delete(String name) async {
    try {
      if (!_isSignedIn) {
        return false;
      }
      
      final ref = _getSaveRef(name);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }
  
  @override
  Future<List<SaveInfo>> listSaves() async {
    try {
      if (!_isSignedIn) {
        return [];
      }
      
      final saves = <SaveInfo>[];
      final ref = _storage.ref('saves/$_userId');
      
      try {
        final result = await ref.listAll();
        
        for (final item in result.items) {
          if (item.name.startsWith(SAVE_PREFIX)) {
            try {
              // Récupérer les métadonnées
              final metadata = await item.getMetadata();
              final lastSaved = metadata.customMetadata?['lastSaved'];
              
              // Récupérer les données
              final data = await item.getData();
              if (data == null) continue;
              
              final jsonString = utf8.decode(data);
              final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
              
              // Extraire les informations de sauvegarde
              final gameData = jsonData['gameData'] as Map<String, dynamic>?;
              final playerData = gameData?['playerManager'] as Map<String, dynamic>?;
              
              if (playerData != null) {
                final name = item.name.substring(SAVE_PREFIX.length, item.name.length - 5); // Enlever .json
                
                saves.add(SaveInfo(
                  id: jsonData['id'] as String? ?? name,
                  name: name,
                  timestamp: DateTime.parse(lastSaved ?? jsonData['timestamp'] as String),
                  version: jsonData['version'] as String? ?? GameConstants.VERSION,
                  paperclips: (playerData['paperclips'] as num?)?.toDouble() ?? 0.0,
                  money: (playerData['money'] as num?)?.toDouble() ?? 0.0,
                  isSyncedWithCloud: true,
                  cloudId: item.fullPath,
                  gameMode: jsonData['gameMode'] != null 
                      ? GameMode.values[jsonData['gameMode'] as int] 
                      : GameMode.INFINITE,
                ));
              }
            } catch (e) {
              debugPrint('Erreur lors du chargement de la sauvegarde ${item.name}: $e');
            }
          }
        }
        
        // Trier par date de sauvegarde (plus récent d'abord)
        saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (e) {
        debugPrint('Erreur lors de la liste des sauvegardes: $e');
      }
      
      return saves;
    } catch (e) {
      debugPrint('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }
} 