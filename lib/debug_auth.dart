import 'package:flutter/material.dart';
import 'services/api/api_client.dart';
import 'services/api/auth_service.dart';
import 'services/user/google_auth_service.dart';
import 'config/api_config.dart';
import 'env_config.dart';

/// Widget pour tester et déboguer l'authentification
class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({Key? key}) : super(key: key);

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  final TextEditingController _logController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConfig();
  }

  void _log(String message) {
    setState(() {
      _logController.text += "$message\n";
    });
    debugPrint(message);
  }

  Future<void> _checkConfig() async {
    _log("=== VÉRIFICATION DE LA CONFIGURATION ===");
    
    // Vérifier les configurations API
    _log("API Base URL: ${ApiConfig.apiBaseUrl}");
    _log("API URL depuis EnvConfig: ${EnvConfig.apiBaseUrl}");
    
    // Vérifier si le .env est chargé
    _log("Google Client ID: ${EnvConfig.googleClientId}");
    _log("API Key: ${EnvConfig.apiKey.isEmpty ? 'Non définie' : 'Définie'}");
    
    // Vérifier l'état de l'authentification
    final authService = AuthService();
    _log("AuthService.isAuthenticated: ${authService.isAuthenticated}");
    
    final googleAuthService = GoogleAuthService();
    _log("GoogleAuthService.isSignedIn: ${googleAuthService.isSignedIn}");
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _log("\n=== TEST DE CONNEXION API ===");
      final apiClient = ApiClient();
      
      try {
        _log("Tentative de connexion à ${ApiConfig.apiBaseUrl}/health...");
        final response = await apiClient.get('/health', requiresAuth: false);
        _log("Réponse: $response");
      } catch (e) {
        _log("Erreur de connexion: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleAuth() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _log("\n=== TEST D'AUTHENTIFICATION GOOGLE ===");
      
      final googleAuthService = GoogleAuthService();
      
      try {
        _log("Tentative de connexion avec Google...");
        final result = await googleAuthService.signInWithGoogle();
        
        if (result != null) {
          _log("Connexion réussie!");
          _log("ID: ${result['id']}");
          _log("Nom: ${result['displayName']}");
          _log("Email: ${result['email']}");
        } else {
          _log("Échec de la connexion Google: résultat null");
        }
      } catch (e) {
        _log("Erreur d'authentification Google: $e");
      }
      
      _log("État de connexion après tentative: ${googleAuthService.isSignedIn}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthService() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _log("\n=== TEST D'AUTHENTIFICATION API ===");
      
      final authService = AuthService();
      
      try {
        _log("Tentative de connexion avec Google via AuthService...");
        final result = await authService.signInWithGoogle();
        
        _log("Résultat: $result");
        _log("User ID: ${authService.userId}");
        _log("Username: ${authService.username}");
        _log("isAuthenticated: ${authService.isAuthenticated}");
      } catch (e) {
        _log("Erreur d'authentification API: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débogage Authentification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testApiConnection,
                    child: const Text('Tester API'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGoogleAuth,
                    child: const Text('Tester Google'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAuthService,
                    child: const Text('Tester AuthService'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) 
              const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _logController,
                maxLines: null,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Logs',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
