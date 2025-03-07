import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_save_service.dart';

class SaveService implements ISaveService {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  static const String _savePrefix = 'save_';
  static const String _backupPrefix = 'backup_';
  static const String _userId = 'local_user'; // À remplacer par l'ID réel de l'utilisateur

  SaveService(this._prefs) : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    // Initialisation si nécessaire
  }

  @override
  Future<void> saveGame(String slot, Map<String, dynamic> data) async {
    final key = _savePrefix + slot;
    await _prefs.setString(key, jsonEncode(data));
    await _syncToCloud(slot, data);
  }

  @override
  Future<Map<String, dynamic>> loadGame(String slot) async {
    final key = _savePrefix + slot;
    final data = _prefs.getString(key);
    if (data == null) {
      throw Exception('No save data found for slot: $slot');
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteGame(String slot) async {
    final key = _savePrefix + slot;
    await _prefs.remove(key);
    await _deleteFromCloud(slot);
  }

  @override
  Future<List<String>> listSaveSlots() async {
    final keys = _prefs.getKeys();
    return keys
        .where((key) => key.startsWith(_savePrefix))
        .map((key) => key.substring(_savePrefix.length))
        .toList();
  }

  @override
  Future<void> syncWithCloud() async {
    try {
      final slots = await listSaveSlots();
      for (final slot in slots) {
        final localData = await loadGame(slot);
        await _syncToCloud(slot, localData);
      }
    } catch (e) {
      print('Error syncing with cloud: $e');
      rethrow;
    }
  }

  @override
  Future<void> backupGame(String slot) async {
    final saveData = await loadGame(slot);
    final backupKey = _backupPrefix + slot;
    await _prefs.setString(backupKey, jsonEncode(saveData));
    await _backupToCloud(slot, saveData);
  }

  @override
  Future<void> restoreFromBackup(String slot) async {
    final backupKey = _backupPrefix + slot;
    final backupData = _prefs.getString(backupKey);
    if (backupData == null) {
      throw Exception('No backup found for slot: $slot');
    }
    final data = jsonDecode(backupData) as Map<String, dynamic>;
    await saveGame(slot, data);
  }

  Future<void> _syncToCloud(String slot, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('saves')
          .doc(slot)
          .set({
        'data': data,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error syncing to cloud: $e');
      rethrow;
    }
  }

  Future<void> _deleteFromCloud(String slot) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('saves')
          .doc(slot)
          .delete();
    } catch (e) {
      print('Error deleting from cloud: $e');
      rethrow;
    }
  }

  Future<void> _backupToCloud(String slot, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('backups')
          .doc(slot)
          .set({
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error backing up to cloud: $e');
      rethrow;
    }
  }
} 