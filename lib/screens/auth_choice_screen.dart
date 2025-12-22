import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/notification_manager.dart';
import '../services/google/google_bootstrap.dart';
import '../services/google/cloudsave/cloud_save_service.dart';
import '../services/google/cloudsave/cloud_save_models.dart';
import '../services/google/sync/sync_orchestrator.dart';
import '../services/google/sync/sync_readiness_port.dart';
import '../services/google/identity/identity_status.dart';
import '../services/supabase/supabase_auth_linker.dart';
import '../services/identity/email_identity_service.dart';
import '../services/google/identity/google_identity_service.dart';
import '../presentation/google/google_control_center.dart';

class _InlineReadiness implements SyncReadinessPort {
  final GoogleIdentityService identity;
  final ValueListenable<bool> enabled;

  const _InlineReadiness({required this.identity, required this.enabled});

  @override
  Future<bool> isSyncAllowed() async {
    return identity.status == IdentityStatus.signedIn && enabled.value == true;
  }

  @override
  Future<bool> hasNetwork() async {
    return true;
  }
}

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
              icon: const Icon(Icons.games_outlined),
              label: const Text('Se connecter avec Google'),
              onPressed: () async {
                final google = context.read<GoogleServicesBundle>();
                final cloud = context.read<CloudSaveService>();
                final state = context.read<GameState>();
                // 1) Tenter d'abord la connexion Google Play Games (pour obtenir playerId)
                final st = await google.identity.signIn();
                if (st != IdentityStatus.signedIn) {
                  NotificationManager.instance.showNotification(
                    message: 'Connexion Google Play Games échouée',
                    level: NotificationLevel.ERROR,
                  );
                  return;
                }
                // 2) Établir (ou réutiliser) la session Supabase OAuth liée à Google
                try {
                  await SupabaseAuthLinker.ensureGoogleSession();
                } catch (e) {
                  NotificationManager.instance.showNotification(
                    message: 'Session Supabase non établie: $e',
                    level: NotificationLevel.ERROR,
                  );
                }
                final syncEnabled = ValueNotifier<bool>(true);
                final readiness = _InlineReadiness(identity: google.identity, enabled: syncEnabled);
                final orchestrator = GoogleSyncOrchestrator(
                  achievements: google.achievements,
                  leaderboards: google.leaderboards,
                  cloud: cloud,
                  readiness: readiness,
                );
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return GoogleControlCenter(
                      identity: google.identity,
                      achievements: google.achievements,
                      leaderboards: google.leaderboards,
                      cloud: cloud,
                      orchestrator: orchestrator,
                      readiness: readiness,
                      syncEnabled: syncEnabled,
                      buildLocalRecord: () async {
                        if (google.identity.playerId == null) {
                          throw StateError('Non connecté à Google Play Games');
                        }
                        final snapshot = state.toSnapshot().toJson();
                        final info = await PackageInfo.fromPlatform();
                        final device = CloudSaveDeviceInfo(
                          model: '?',
                          platform: Platform.isAndroid ? 'android' : 'other',
                          locale: 'fr-FR',
                        );
                        final display = CloudSaveDisplayData(
                          money: 0,
                          paperclips: 0,
                          autoClipperCount: 0,
                          netProfit: 0,
                        );
                        return cloud.buildRecord(
                          playerId: google.identity.playerId!,
                          appVersion: '${info.version}+${info.buildNumber}',
                          gameSnapshot: snapshot,
                          displayData: display,
                          device: device,
                        );
                      },
                      applyCloudImport: (_) async {},
                    );
                  }));
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
