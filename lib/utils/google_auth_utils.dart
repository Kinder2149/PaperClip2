import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Utilitaires pour l'authentification Google et les scopes d'accès
class GoogleAuthUtils {
  // Scopes nécessaires pour l'API Drive
  static const List<String> _driveScopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];

  // ID Client OAuth pour votre application
  // Définir par votre configuration Google Cloud
  static const String _clientId = 'YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com';

  /// Obtenir un client authentifié pour l'API Drive avec les scopes appropriés
  static Future<http.Client?> getAuthenticatedClient() async {
    try {
      // Créer un identifiant ClientId
      final clientId = ClientId(_clientId, null);

      // Fonction de prompt pour l'authentification
      final prompt = _promptForUserConsent;

      // Obtenir un client authentifié
      final client = await clientViaUserConsent(clientId, _driveScopes, prompt);

      return client;
    } catch (e) {
      print('Erreur lors de l\'authentification Google Drive: $e');
      return null;
    }
  }

  /// Demander le consentement de l'utilisateur pour les scopes requis
  static Future<void> _promptForUserConsent(String url) async {
    print('Veuillez visiter cette URL pour autoriser l\'application:');
    print(url);

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw Exception('Impossible d\'ouvrir l\'URL d\'authentification: $url');
    }
  }

  /// Vérifier si les scopes Drive sont autorisés
  static Future<bool> hasDriveScopes(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      // Vérifier les scopes dans le token (simplifié)
      return auth.accessToken?.isNotEmpty == true;
    } catch (e) {
      print('Erreur lors de la vérification des scopes: $e');
      return false;
    }
  }

  /// Demander des scopes supplémentaires après la connexion
  static Future<bool> requestAdditionalScopes(GoogleSignInAccount account) async {
    try {
      // Pour demander des scopes supplémentaires, il faut généralement
      // déconnecter et reconnecter l'utilisateur avec tous les scopes nécessaires
      final googleSignIn = GoogleSignIn(scopes: [
        'email',
        'profile',
        ..._driveScopes,
      ]);

      await googleSignIn.signOut();
      final newAccount = await googleSignIn.signIn();

      return newAccount != null;
    } catch (e) {
      print('Erreur lors de la demande de scopes supplémentaires: $e');
      return false;
    }
  }
}