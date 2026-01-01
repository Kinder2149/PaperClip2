import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../services/notification_manager.dart';
import '../services/google/google_bootstrap.dart';
import '../services/auth/firebase_auth_service.dart';
import '../services/identity/email_identity_service.dart';
import '../services/google/identity/google_identity_service.dart';
// Flux Control Center global supprimé

class AuthChoiceScreen extends StatelessWidget {
  final EmailIdentityService? emailService;
  const AuthChoiceScreen({super.key, this.emailService});

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
                  await FirebaseAuthService.instance.signInWithGoogle();
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
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('Se connecter avec Email'),
              onPressed: () async {
                final emailCtrl = TextEditingController();
                final passCtrl = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Connexion Email'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                        TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final svc = emailService ?? EmailIdentityService();
                            await svc.signInWithEmail(email: emailCtrl.text.trim(), password: passCtrl.text);
                            if (context.mounted) Navigator.pop(context);
                            NotificationManager.instance.showNotification(message: 'Connecté (Email)', level: NotificationLevel.INFO);
                          } catch (e) {
                            NotificationManager.instance.showNotification(message: 'Erreur: $e', level: NotificationLevel.ERROR);
                          }
                        },
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
