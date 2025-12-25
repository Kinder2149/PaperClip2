import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/widgets/google/google_account_button.dart';

class GoogleAccountAction extends StatelessWidget {
  const GoogleAccountAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GoogleAccountButton(
        fullWidth: false,
        compact: true,
        showAvatar: true,
        backgroundColor: Colors.transparent,
        textColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () async {
          final google = context.read<GoogleServicesBundle>();
          final identity = google.identity;
          try {
            if (identity.status != IdentityStatus.signedIn) {
              await identity.signIn();
              final newStatus = identity.status;
              if (context.mounted) {
                final msg = newStatus == IdentityStatus.signedIn
                    ? 'Connecté à Google Play Games'
                    : 'Connexion Google non effectuée';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
              return;
            }

            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Se déconnecter de Google'),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await identity.signOut();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Déconnecté de Google Play Games')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur déconnexion: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur Google: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
