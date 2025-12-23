import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/constants/game_config.dart';
// import 'package:paperclip2/services/google/snapshots/snapshots_cloud_save.dart';

class GoogleProfileScreen extends StatelessWidget {
  const GoogleProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GoogleIdentityService identity =
        context.watch<GoogleServicesBundle>().identity;

    final displayName = (identity.displayName ?? '').trim();
    final playerId = identity.playerId ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Google')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AvatarOrIcon(identity: identity),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty ? displayName : 'Joueur Google',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      if (playerId.isNotEmpty)
                        Text('ID: $playerId', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            FutureBuilder<_ProfileStats>(
              future: _loadStats(context, playerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data ?? const _ProfileStats();
                return Row(
                  children: [
                    _ChipStat(label: 'Infini', value: stats.infiniteCount.toString(), color: Colors.blue),
                    const SizedBox(width: 8),
                    _ChipStat(label: 'Compétition', value: stats.competitiveCount.toString(), color: Colors.orange),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_ProfileStats> _loadStats(BuildContext context, String playerId) async {
    // Local: nous ne stockons pas encore playerId dans les métadonnées → compteur global.
    // Cloud: le slot GPG est implicitement lié au playerId connecté.
    try {
      final metas = await SaveManagerAdapter.instance.listSaves();
      int infinite = 0;
      int competitive = 0;
      for (final m in metas) {
        if (m.gameMode == GameMode.COMPETITIVE) {
          competitive++;
        } else {
          infinite++;
        }
      }

      // Cloud GPG global désactivé (PHASE 1): ne pas compter le slot GPG global

      return _ProfileStats(infiniteCount: infinite, competitiveCount: competitive);
    } catch (_) {
      return const _ProfileStats();
    }
  }
}

class _AvatarOrIcon extends StatelessWidget {
  final GoogleIdentityService identity;
  const _AvatarOrIcon({required this.identity});
  @override
  Widget build(BuildContext context) {
    final url = identity.avatarUrl ?? '';
    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(url));
    }
    return const CircleAvatar(radius: 24, child: Icon(Icons.person));
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ChipStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label  $value', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}

class _ProfileStats {
  final int infiniteCount;
  final int competitiveCount;
  const _ProfileStats({this.infiniteCount = 0, this.competitiveCount = 0});
}
