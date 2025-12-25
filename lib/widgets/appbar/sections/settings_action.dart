// lib/widgets/appbar/sections/settings_action.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/identity/identity_status.dart';

class SettingsAction extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const SettingsAction({
    Key? key, 
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.white,
      ),
      onPressed: onPressed ?? () async {
        // Panneau paramètres: éléments de connexion Google (et extensions futures)
        final google = context.read<GoogleServicesBundle>();
        final identity = google.identity;

        showModalBottomSheet(
          context: context,
          builder: (ctx) {
            final name = (identity.displayName ?? '').trim();
            final avatarUrl = identity.avatarUrl ?? '';
            final isSignedIn = identity.status == IdentityStatus.signedIn;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(isSignedIn
                        ? (name.isNotEmpty ? name : 'Connecté à Google Play Games')
                        : 'Se connecter à Google Play Games'),
                    trailing: (avatarUrl.startsWith('http'))
                        ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(avatarUrl))
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        if (!isSignedIn) {
                          await identity.signIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connexion Google réussie')),
                            );
                          }
                        } else {
                          await identity.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Déconnexion Google effectuée')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur Google: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
      tooltip: 'Paramètres',
    );
  }
}
