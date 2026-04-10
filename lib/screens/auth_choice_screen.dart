import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../services/notification_manager.dart';
import '../services/app_bootstrap_controller.dart';
import '../services/google/google_bootstrap.dart';
import '../services/auth/firebase_auth_service.dart';
import '../services/google/identity/google_identity_service.dart';
// Flux Control Center global supprimé

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Se connecter avec Google (Firebase)'),
              onPressed: () async {
                try {
                  // CORRECTION AUTH-CLOUD-FIABILISATION: Utiliser AppBootstrapController pour centraliser l'auth
                  await context.read<AppBootstrapController>().requestGoogleSignIn();
                  final token = await FirebaseAuthService.instance.getIdToken();
                  NotificationManager.instance.showNotification(
                    message: token != null ? 'Connecté (Firebase). ID Token reçu.' : 'Connecté (Firebase). Pas d\'ID Token.',
                    level: NotificationLevel.INFO,
                  );
                } catch (e) {
                  NotificationManager.instance.showNotification(
                    message: 'Connexion Google/Firebase échouée: $e',
                    level: NotificationLevel.ERROR,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            // Bouton REST retiré (Firebase Callable uniquement)
          ],
        ),
      ),
    );
  }
}
