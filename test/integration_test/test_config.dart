import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration pour les tests d'intégration E2E
class TestConfig {
  static Future<void> initialize() async {
    // Charger les variables d'environnement de test
    await dotenv.load(fileName: '.env.test');
  }
  
  static String get functionsApiBase => 
    dotenv.env['FUNCTIONS_API_BASE'] ?? 'http://localhost:5001/paperclip-98294/us-central1/api';
  
  static String get testUserEmail => 
    dotenv.env['TEST_USER_EMAIL'] ?? 'test@paperclip2.com';
  
  static String get testUserPassword => 
    dotenv.env['TEST_USER_PASSWORD'] ?? 'test123456';
  
  static bool get useEmulator =>
    dotenv.env['USE_EMULATOR']?.toLowerCase() == 'true';
}
