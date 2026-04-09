// Mocks simples pour Tests E2E - Phase 4
// Version simplifiée sans Mockito pour démarrage rapide

import 'package:paperclip2/services/persistence/game_snapshot.dart';

/// Mock simple pour Firebase Auth
class MockFirebaseAuth {
  String? _currentUid;
  String? _currentEmail;
  String? _currentToken;
  
  void mockUser({required String uid, String? email}) {
    _currentUid = uid;
    _currentEmail = email ?? 'test@example.com';
    _currentToken = 'mock-token-$uid';
  }
  
  void mockToken(String token) {
    _currentToken = token;
  }
  
  void mockTokenRefresh() {
    _currentToken = 'refreshed-token-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  void mockSignOut() {
    _currentUid = null;
    _currentEmail = null;
    _currentToken = null;
  }
  
  String? get currentUid => _currentUid;
  String? get currentEmail => _currentEmail;
  String? get currentToken => _currentToken;
  
  bool get isSignedIn => _currentUid != null;
}

/// Mock simple pour HTTP Client Cloud
class MockHttpClient {
  final List<String> _callLog = [];
  Map<String, dynamic>? _nextPullResponse;
  Exception? _nextError;
  int _failCount = 0;
  int _currentFailCount = 0;
  bool _shouldTimeout = false;
  
  void reset() {
    _callLog.clear();
    _nextPullResponse = null;
    _nextError = null;
    _failCount = 0;
    _currentFailCount = 0;
    _shouldTimeout = false;
  }
  
  // Configuration des réponses
  void mockPushSuccess({String? enterpriseId}) {
    _nextError = null;
  }
  
  void mockPullSuccess({
    String? enterpriseId,
    Map<String, dynamic>? snapshot,
  }) {
    _nextPullResponse = snapshot ?? {
      'metadata': {'lastSaved': DateTime.now().toIso8601String()},
      'core': {
        'enterpriseId': enterpriseId ?? '550e8400-e29b-41d4-a716-446655440000',
        'enterpriseName': 'Test Enterprise',
        'level': 1,
        'money': 100.0,
        'metal': 50.0,
        'paperclips': 0,
      },
    };
    _nextError = null;
  }
  
  void mockDeleteSuccess({String? enterpriseId}) {
    _nextError = null;
  }
  
  void mockNetworkError() {
    _nextError = Exception('Network error');
  }
  
  void mockServerError() {
    _nextError = Exception('Server error (500)');
  }
  
  void mockUnauthorized() {
    _nextError = Exception('Unauthorized (401)');
  }
  
  void mockTimeout({Duration? duration}) {
    _shouldTimeout = true;
  }
  
  void mockInvalidJson() {
    _nextPullResponse = {'invalid': 'json'};
  }
  
  void mockNetworkErrorThenSuccess({required int failCount}) {
    _failCount = failCount;
    _currentFailCount = 0;
  }
  
  // Simulations d'appels
  Future<void> push({
    required String enterpriseId,
    required Map<String, dynamic> snapshot,
    Map<String, dynamic>? metadata,
    String? token,
  }) async {
    _callLog.add('push:$enterpriseId');
    
    if (_shouldTimeout) {
      await Future.delayed(const Duration(seconds: 35));
      throw Exception('Timeout');
    }
    
    if (_failCount > 0 && _currentFailCount < _failCount) {
      _currentFailCount++;
      throw Exception('Network error (retry $_currentFailCount/$_failCount)');
    }
    
    if (_nextError != null) {
      throw _nextError!;
    }
    
    // Succès
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<Map<String, dynamic>?> pull({
    required String enterpriseId,
    String? token,
  }) async {
    _callLog.add('pull:$enterpriseId');
    
    if (_shouldTimeout) {
      await Future.delayed(const Duration(seconds: 35));
      throw Exception('Timeout');
    }
    
    if (_nextError != null) {
      throw _nextError!;
    }
    
    // Succès
    await Future.delayed(const Duration(milliseconds: 100));
    return _nextPullResponse;
  }
  
  Future<void> delete({
    required String enterpriseId,
    String? token,
  }) async {
    _callLog.add('delete:$enterpriseId');
    
    if (_nextError != null) {
      throw _nextError!;
    }
    
    // Succès
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  // Vérifications
  List<String> get callLog => List.unmodifiable(_callLog);
  
  int countCalls(String operation) {
    return _callLog.where((call) => call.startsWith(operation)).length;
  }
  
  bool wasCalled(String operation, {String? enterpriseId}) {
    if (enterpriseId != null) {
      return _callLog.contains('$operation:$enterpriseId');
    }
    return _callLog.any((call) => call.startsWith(operation));
  }
}

/// Factory pour créer des snapshots de test
class TestSnapshotFactory {
  static GameSnapshot create({
    int level = 1,
    double money = 100.0,
    double metal = 50.0,
    int paperclips = 0,
    String? enterpriseId,
    String? enterpriseName,
    DateTime? lastSaved,
  }) {
    return GameSnapshot(
      metadata: {
        'lastSaved': (lastSaved ?? DateTime.now()).toIso8601String(),
        'deviceInfo': 'test-device',
        'appVersion': '1.0.0',
      },
      core: {
        'level': level,
        'money': money,
        'metal': metal,
        'paperclips': paperclips,
        'enterpriseId': enterpriseId ?? '550e8400-e29b-41d4-a716-446655440000',
        'enterpriseName': enterpriseName ?? 'Test Enterprise',
      },
    );
  }
  
  static GameSnapshot createLarge({int sizeMB = 10}) {
    final base = create();
    
    // Ajouter données pour atteindre taille cible
    final largeData = List.generate(
      sizeMB * 1024 * 10,
      (i) => 'data_$i' * 100,
    );
    
    return GameSnapshot(
      metadata: base.metadata,
      core: {
        ...base.core,
        'largeData': largeData,
      },
    );
  }
}
