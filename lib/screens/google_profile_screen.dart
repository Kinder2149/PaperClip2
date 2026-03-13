import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:intl/intl.dart';

class GoogleProfileScreen extends StatefulWidget {
  const GoogleProfileScreen({super.key});

  @override
  State<GoogleProfileScreen> createState() => _GoogleProfileScreenState();
}

class _GoogleProfileScreenState extends State<GoogleProfileScreen> {
  _ProfileStats? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);

    try {
      final entries = await SaveAggregator().listAll(context);
      final nonBackupEntries = entries.where((e) => !e.isBackup).toList();

      int infinite = 0;
      int competitive = 0;
      int totalPaperclips = 0;
      double totalMoney = 0;

      for (final entry in nonBackupEntries) {
        if (entry.gameMode == GameMode.COMPETITIVE) {
          competitive++;
        } else {
          infinite++;
        }
        totalPaperclips += entry.paperclips;
        totalMoney += entry.money;
      }

      if (!mounted) return;
      setState(() {
        _stats = _ProfileStats(
          infiniteCount: infinite,
          competitiveCount: competitive,
          totalWorlds: nonBackupEntries.length,
          totalPaperclips: totalPaperclips,
          totalMoney: totalMoney,
        );
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stats = const _ProfileStats();
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: FirebaseAuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        final firebaseUser = FirebaseAuthService.instance.currentUser;
        final GoogleIdentityService identity = context.watch<GoogleServicesBundle>().identity;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Mon Profil'),
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Profil Principal
                  _buildProfileCard(context, firebaseUser, identity),
                  
                  const SizedBox(height: 16),
                  
                  // Card Statistiques
                  _buildStatsCard(context),
                  
                  const SizedBox(height: 16),
                  
                  // Card Informations Techniques
                  _buildTechnicalInfoCard(context, firebaseUser, identity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic firebaseUser, GoogleIdentityService identity) {
    final displayName = identity.displayName ?? firebaseUser?.email?.split('@').first ?? 'Joueur';
    final email = firebaseUser?.email ?? 'Non connecté';
    final avatarUrl = identity.avatarUrl;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar avec bordure
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple[50],
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 40, color: Colors.deepPurple)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                // Nom et Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (firebaseUser != null)
                            const Icon(
                              Icons.verified,
                              size: 20,
                              color: Colors.green,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    if (_loadingStats) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final stats = _stats ?? const _ProfileStats();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grille de stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatItem(
                  icon: Icons.public,
                  label: 'Mondes',
                  value: stats.totalWorlds.toString(),
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.content_cut,
                  label: 'Trombones',
                  value: NumberFormat.compact().format(stats.totalPaperclips),
                  color: Colors.purple,
                ),
                _buildStatItem(
                  icon: Icons.all_inclusive,
                  label: 'Mode Infini',
                  value: stats.infiniteCount.toString(),
                  color: Colors.teal,
                ),
                _buildStatItem(
                  icon: Icons.monetization_on,
                  label: 'Argent Total',
                  value: NumberFormat.compact().format(stats.totalMoney),
                  color: Colors.green,
                ),
              ],
            ),
            if (stats.competitiveCount > 0) ...[
              const SizedBox(height: 12),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Mode Compétitif',
                value: stats.competitiveCount.toString(),
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfoCard(BuildContext context, dynamic firebaseUser, GoogleIdentityService identity) {
    final playerId = identity.playerId ?? 'Non disponible';
    final uid = firebaseUser?.uid ?? 'Non connecté';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Informations Techniques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Firebase UID', uid),
            const SizedBox(height: 8),
            _buildInfoRow('Google Play ID', playerId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProfileStats {
  final int infiniteCount;
  final int competitiveCount;
  final int totalWorlds;
  final int totalPaperclips;
  final double totalMoney;
  
  const _ProfileStats({
    this.infiniteCount = 0,
    this.competitiveCount = 0,
    this.totalWorlds = 0,
    this.totalPaperclips = 0,
    this.totalMoney = 0,
  });
}
