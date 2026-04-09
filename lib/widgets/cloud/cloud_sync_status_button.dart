// lib/widgets/cloud/cloud_sync_status_button.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/widgets/worlds/world_state_helper.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/utils/logger.dart';

/// Entrée simplifiée attendue depuis SaveAggregator.listAll
class CloudAwareSaveEntry {
  final String id;
  final String name;
  final bool isBackup;
  final String? cloudSyncState; // in_sync | ahead_local | ahead_remote | diverged | null
  final bool isCloudSource;

  CloudAwareSaveEntry({
    required this.id,
    required this.name,
    required this.isBackup,
    required this.cloudSyncState,
    required this.isCloudSource,
  });

  factory CloudAwareSaveEntry.fromSaveEntry(dynamic save) {
    // save is expected to expose: id, name, isBackup, cloudSyncState, source
    return CloudAwareSaveEntry(
      id: save.id as String,
      name: save.name as String,
      isBackup: save.isBackup as bool,
      cloudSyncState: save.cloudSyncState as String?,
      isCloudSource: (save.source.toString().toLowerCase().contains('cloud')),
    );
  }

  bool get _verbose {
    final raw = (dotenv.env['DEBUG_VERBOSE_LOGS'] ?? 'false').toLowerCase().trim();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
}

/// Widget réutilisable affichant l'état cloud et proposant un push si nécessaire.
class CloudSyncStatusButton extends StatefulWidget {
  final dynamic saveEntry; // SaveEntry

  const CloudSyncStatusButton({Key? key, required this.saveEntry}) : super(key: key);

  @override
  State<CloudSyncStatusButton> createState() => _CloudSyncStatusButtonState();
}

class _CloudSyncStatusButtonState extends State<CloudSyncStatusButton> {
  bool _pushing = false;
  final Logger _logger = Logger.forComponent('ui-cloud-button');

  bool get _cloudFeatureOn => (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';

  @override
  Widget build(BuildContext context) {
    final entry = CloudAwareSaveEntry.fromSaveEntry(widget.saveEntry);
    // Observer l'identité pour propager les changements UI automatiquement
    final google = context.watch<GoogleServicesBundle>();
    // Ne rien afficher pour les backups (mais log quand même)
    if (entry.isBackup) {
      if (kDebugMode && entry._verbose) {
        _logger.debug('[CLOUD] skip (backup) id=${entry.id} name=${entry.name}');
      }
      return const SizedBox.shrink();
    }

    // Lire l'identité si disponible (pour logs et état Connexion requise)
    String? playerId;
    String identityStatus = 'unknown';
    try {
      playerId = google.identity.playerId;
      identityStatus = google.identity.status.toString();
    } catch (_) {}

    // 1) Récupérer l'état Cloud activé depuis SharedPreferences (préférence utilisateur)
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getBool('cloud_enabled') ?? false),
      builder: (context, cloudSnap) {
        final cloudOn = cloudSnap.data ?? false;
        // 2) Puis récupérer l'état canonique (pending/synced/local_only)
        return FutureBuilder<String>(
          future: WorldStateHelper.canonicalStateFor(widget.saveEntry as dynamic),
          builder: (context, snapshot) {
            final canonical = snapshot.data ?? 'local_only';
            if (kDebugMode && entry._verbose) {
              _logger.debug('[CLOUD] build id='+entry.id+' canonical='+canonical+' cloudOn='+cloudOn.toString()+' signedIn='+identityStatus);
            }
            // Upload en cours local (transitoire interne au widget)
            if (_pushing) {
              return _buildChip(
                label: 'Synchronisation…',
                color: Colors.blue.shade100,
                icon: Icons.cloud_upload,
                isBusy: true,
              );
            }

            // Cloud désactivé
            if (!cloudOn) {
              return _buildChip(
                label: 'Cloud indisponible',
                color: Colors.blueGrey.shade100,
                icon: Icons.cloud_off,
              );
            }

            // Pas d'identité disponible
            if (playerId == null || playerId.isEmpty) {
              return _buildChip(
                label: 'Connexion requise',
                color: Colors.amber.shade100,
                icon: Icons.person_off,
              );
            }

            switch (canonical) {
              case 'cloud_synced':
                return _buildChip(
                  label: 'À jour',
                  color: Colors.green.shade100,
                  icon: Icons.cloud_done,
                );
              case 'cloud_pending':
                return _buildChip(
                  label: 'À synchroniser',
                  color: Colors.orange.shade100,
                  icon: Icons.cloud_upload,
                );
              case 'cloud_error':
                return _buildChip(
                  label: 'Erreur de synchronisation',
                  color: Colors.red.shade100,
                  icon: Icons.error_outline,
                );
              case 'local_only':
              default:
                return _buildChip(
                  label: 'Local uniquement',
                  color: Colors.blueGrey.shade50,
                  icon: Icons.storage,
                );
            }
          },
        );
      },
    );
  }

  Widget _buildAction({required String label, required Color color, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color, required IconData icon, bool isBusy = false}) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy) SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700)) else Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pushNow(BuildContext context, String enterpriseId) async {
    // Normalisation: pas de push cloud depuis l'UI
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La synchronisation cloud est automatique (création/arrêt/pause).')),
    );
  }
}
