import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_leaderboard_service.dart';

class LeaderboardService implements ILeaderboardService {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  static const String _leaderboardPrefix = 'leaderboard_';
  static const int _maxEntries = 100;
  static const String _userId = 'local_user'; // À remplacer par l'ID réel de l'utilisateur

  LeaderboardService(this._prefs) : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    // Initialisation si nécessaire
  }

  @override
  Future<void> submitScore(String leaderboardId, int score) async {
    final key = _leaderboardPrefix + leaderboardId;
    final entries = await _getLeaderboardEntries(leaderboardId);
    
    // Ajouter le nouveau score
    entries.add({
      'playerId': _userId,
      'playerName': 'Joueur Local', // TODO: Remplacer par le nom réel du joueur
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Trier par score décroissant
    entries.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Garder uniquement les meilleurs scores
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }

    // Sauvegarder localement
    await _prefs.setString(key, jsonEncode(entries));
    
    // Synchroniser avec le cloud
    await _syncLeaderboardToCloud(leaderboardId, entries);
  }

  @override
  Future<void> showLeaderboard(String leaderboardId) async {
    final entries = await getTopScores(leaderboardId, _maxEntries);
    // TODO: Implémenter l'affichage du classement dans l'UI
    print('Leaderboard $leaderboardId: $entries');
  }

  @override
  Future<List<Map<String, dynamic>>> getTopScores(String leaderboardId, int limit) async {
    final entries = await _getLeaderboardEntries(leaderboardId);
    return entries.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>?> getPlayerScore(String leaderboardId) async {
    final entries = await _getLeaderboardEntries(leaderboardId);
    return entries.firstWhere(
      (entry) => entry['playerId'] == _userId,
      orElse: () => null,
    );
  }

  @override
  Future<void> syncLeaderboards() async {
    try {
      final leaderboards = await _getAllLeaderboardIds();
      for (final leaderboardId in leaderboards) {
        final entries = await _getLeaderboardEntries(leaderboardId);
        await _syncLeaderboardToCloud(leaderboardId, entries);
      }
    } catch (e) {
      print('Error syncing leaderboards: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getLeaderboardEntries(String leaderboardId) async {
    final key = _leaderboardPrefix + leaderboardId;
    final data = _prefs.getString(key);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<List<String>> _getAllLeaderboardIds() async {
    final keys = _prefs.getKeys();
    return keys
        .where((key) => key.startsWith(_leaderboardPrefix))
        .map((key) => key.substring(_leaderboardPrefix.length))
        .toList();
  }

  Future<void> _syncLeaderboardToCloud(String leaderboardId, List<Map<String, dynamic>> entries) async {
    try {
      final batch = _firestore.batch();
      final leaderboardRef = _firestore
          .collection('leaderboards')
          .doc(leaderboardId);

      // Mettre à jour le document principal
      batch.set(leaderboardRef, {
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalEntries': entries.length,
      });

      // Mettre à jour les entrées individuelles
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final entryRef = leaderboardRef.collection('entries').doc(i.toString());
        batch.set(entryRef, {
          'playerId': entry['playerId'],
          'playerName': entry['playerName'],
          'score': entry['score'],
          'rank': i + 1,
          'timestamp': entry['timestamp'],
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing leaderboard to cloud: $e');
      rethrow;
    }
  }
} 