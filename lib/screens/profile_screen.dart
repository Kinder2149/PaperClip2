// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/runtime/runtime_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'welcome_screen.dart';

/// Page profil moderne et adaptative
/// Affiche les données utilisateur et entreprise de manière dynamique
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = FirebaseAuthService.instance.currentUser;
        final gameState = context.watch<GameState>();
        
        // Si pas connecté, rediriger vers WelcomeScreen
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Mon Profil'),
            elevation: 0,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Rafraîchir les données si nécessaire
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserCard(context, user),
                  const SizedBox(height: 16),
                  _buildEnterpriseCard(context, gameState),
                  const SizedBox(height: 16),
                  _buildStatsCard(context, gameState),
                  const SizedBox(height: 16),
                  _buildActionsCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Card Utilisateur - Avatar, nom, email, badge connecté
  Widget _buildUserCard(BuildContext context, dynamic user) {
    final googleIdentity = context.watch<GoogleServicesBundle>().identity;
    final displayName = googleIdentity.displayName ?? user.email?.split('@').first ?? 'Utilisateur';
    final email = user.email ?? 'Non disponible';
    final avatarUrl = googleIdentity.avatarUrl;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
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
                    ? const Icon(Icons.person, size: 40, color: Colors.deepPurple)
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Connecté',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card Entreprise - Nom, date création, ID
  Widget _buildEnterpriseCard(BuildContext context, GameState gameState) {
    final hasEnterprise = gameState.enterpriseId != null && gameState.enterpriseId!.isNotEmpty;
    final enterpriseName = hasEnterprise ? gameState.enterpriseName : 'Pas encore créée';
    final enterpriseId = gameState.enterpriseId ?? 'N/A';
    final createdAt = gameState.enterpriseCreatedAt;

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
                Icon(Icons.business, color: hasEnterprise ? Colors.deepPurple : Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Mon Entreprise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nom entreprise
            _buildInfoRow(
              'Nom',
              enterpriseName,
              icon: Icons.label,
              valueColor: hasEnterprise ? Colors.black87 : Colors.grey,
            ),
            const SizedBox(height: 12),
            
            // Date création
            if (hasEnterprise && createdAt != null)
              _buildInfoRow(
                'Créée le',
                DateFormat('dd/MM/yyyy à HH:mm').format(createdAt),
                icon: Icons.calendar_today,
              ),
            if (hasEnterprise && createdAt != null)
              const SizedBox(height: 12),
            
            // ID entreprise (technique)
            if (hasEnterprise)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Informations techniques',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildInfoRow(
                      'ID Entreprise',
                      enterpriseId,
                      icon: Icons.fingerprint,
                      valueStyle: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            
            // Bouton créer entreprise si pas encore créée
            if (!hasEnterprise) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('Créer mon entreprise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card Statistiques - Quantum, Points Innovation, etc.
  Widget _buildStatsCard(BuildContext context, GameState gameState) {
    final hasEnterprise = gameState.enterpriseId != null && gameState.enterpriseId!.isNotEmpty;
    
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
            
            if (!hasEnterprise)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Créez votre entreprise pour voir vos statistiques',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatItem(
                    icon: Icons.science,
                    emoji: '⚛️',
                    label: 'Quantum',
                    value: NumberFormat.compact().format(gameState.quantum),
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.lightbulb,
                    emoji: '💡',
                    label: 'Points Innovation',
                    value: NumberFormat.compact().format(gameState.pointsInnovation),
                    color: Colors.orange,
                  ),
                  _buildStatItem(
                    icon: Icons.trending_up,
                    emoji: '📈',
                    label: 'Niveau',
                    value: gameState.level.toString(),
                    color: Colors.purple,
                  ),
                  _buildStatItem(
                    icon: Icons.content_cut,
                    emoji: '📎',
                    label: 'Trombones',
                    value: NumberFormat.compact().format(gameState.playerManager.paperclips),
                    color: Colors.green,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Card Actions - Déconnexion, paramètres
  Widget _buildActionsCard(BuildContext context) {
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
                Icon(Icons.settings, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Bouton Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleSignOut(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Zone danger : suppression entreprise
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.red[700]),
                const SizedBox(width: 6),
                Text(
                  'Zone de danger',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleDeleteEnterprise(context),
                icon: Icon(Icons.delete_forever, color: Colors.red[800]),
                label: Text(
                  'Supprimer mon entreprise',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800],
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.red[800]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget item de statistique
  Widget _buildStatItem({
    required IconData icon,
    required String emoji,
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
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

  /// Widget ligne d'information
  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 100,
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
            style: valueStyle ?? TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Gestion de la déconnexion
  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // IMPORTANT : remettre le GameState à zéro en mémoire avant de déconnecter.
      // Sans ça, enterpriseId reste non-null et bloque la navigation post-reconnexion.
      try {
        context.read<GameState>().deleteEnterprise();
        context.read<RuntimeActions>().stopSession();
      } catch (_) {}

      await FirebaseAuthService.instance.signOut();

      try {
        final google = context.read<GoogleServicesBundle>();
        await google.identity.signOut();
      } catch (_) {}

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnecté avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Suppression complète de l'entreprise (local + cloud) avec double confirmation.
  Future<void> _handleDeleteEnterprise(BuildContext context) async {
    // Première confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'entreprise'),
        content: const Text(
          'Cette action est irréversible.\n\n'
          'Toutes vos données de jeu (local et cloud) seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (firstConfirm != true) return;

    // Deuxième confirmation
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dernière confirmation'),
        content: const Text(
          'Confirmez-vous la suppression définitive de votre entreprise et de toutes vos sauvegardes ?\n\n'
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (secondConfirm != true) return;

    try {
      final gameState = context.read<GameState>();
      final enterpriseId = gameState.enterpriseId;

      // 1. Arrêter la session en cours
      try {
        context.read<RuntimeActions>().stopSession();
      } catch (_) {}

      // 2. Supprimer toutes les sauvegardes locales
      // (inclut les résidus d'anciens formats avec des UUID différents)
      try {
        await GamePersistenceOrchestrator.instance.deleteAllLocalSaves();
      } catch (_) {}
      // Garder le deleteSaveById pour compatibilité si deleteAllLocalSaves échoue
      if (enterpriseId != null && enterpriseId.isNotEmpty) {
        try {
          await GamePersistenceOrchestrator.instance.deleteSaveById(enterpriseId);
        } catch (_) {}
      }

      // 3. Supprimer la sauvegarde cloud
      if (enterpriseId != null && enterpriseId.isNotEmpty) {
        try {
          await GamePersistenceOrchestrator.instance
              .deleteCloudById(partieId: enterpriseId);
        } catch (_) {}
      }

      // 4. Réinitialiser le GameState en mémoire
      gameState.deleteEnterprise();

      // 5. Nettoyer les préférences locales liées au cloud
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('cloud_enabled', false);
      } catch (_) {}

      // 6. Supprimer le compte Firebase Auth (Option C)
      String? accountDeleteNote;
      try {
        await FirebaseAuthService.instance.deleteAccount();
        // Compte Firebase Auth supprimé avec succès
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('recent-login') || msg.contains('requires-recent')) {
          accountDeleteNote =
              'Données supprimées. Pour supprimer votre compte Google/Firebase, '
              'rendez-vous dans Firebase Console > Authentication > Users.';
        }
        // Si autre erreur, on continue quand même (données déjà supprimées)
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accountDeleteNote ?? 'Compte et données supprimés définitivement'),
          backgroundColor: accountDeleteNote != null ? Colors.orange : Colors.green,
          duration: Duration(seconds: accountDeleteNote != null ? 8 : 3),
        ),
      );

      // Retour à WelcomeScreen (écran vierge)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
