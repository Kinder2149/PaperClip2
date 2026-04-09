import 'package:paperclip2/models/game_state.dart';

/// Mock du système de persistence pour les tests
class MockGamePersistenceOrchestrator {
  static final instance = MockGamePersistenceOrchestrator._();
  MockGamePersistenceOrchestrator._();
  
  final Map<String, Map<String, dynamic>> _storage = {};
  
  /// Sauvegarder un GameState
  Future<void> saveGame(GameState gs) async {
    if (gs.enterpriseId == null) {
      throw Exception('Enterprise ID is null');
    }
    _storage[gs.enterpriseId!] = gs.toJson();
  }
  
  /// Charger un GameState par ID
  Future<void> loadGameById(GameState gs, String id) async {
    if (!_storage.containsKey(id)) {
      throw Exception('Game not found: $id');
    }
    gs.fromJson(_storage[id]!);
  }
  
  /// Nettoyer le storage (pour setUp/tearDown)
  void clear() => _storage.clear();
  
  /// Vérifier si une sauvegarde existe
  bool hasGame(String id) => _storage.containsKey(id);
}
