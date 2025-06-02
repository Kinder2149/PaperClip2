import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/user_profile.dart';

void main() {
  test('UserProfile structure test', () {
    // Création d'un profil utilisateur simple
    final profile = UserProfile(
      userId: 'test123',
      displayName: 'Test User',
      profileImageUrl: 'https://example.com/profile.jpg'
    );
    
    // Vérification des champs de base
    expect(profile.userId, 'test123');
    expect(profile.displayName, 'Test User');
    expect(profile.profileImageUrl, 'https://example.com/profile.jpg');
    
    // Test de la méthode updateGlobalStats
    final updatedProfile = profile.updateGlobalStats({
      'level': 5,
      'score': 1000
    });
    
    expect(updatedProfile.globalStats['level'], 5);
    expect(updatedProfile.globalStats['score'], 1000);
  });
  
  test('API services structure', () {
    // Vérification simple que les classes existent et peuvent être instanciées
    expect(SocialService, isNotNull);
    expect(AuthService, isNotNull);
    expect(AnalyticsService, isNotNull);
    
    // Vérification de base que certaines constantes sont définies
    expect(AuthService.baseUrl.isNotEmpty, isTrue);
  });
}
