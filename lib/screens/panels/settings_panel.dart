import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel paramètres - Configuration et compte
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              DesignTokens.sectionGap,
              _buildEnterpriseSection(gameState),
              DesignTokens.sectionGap,
              _buildAccountSection(),
              DesignTokens.sectionGap,
              _buildGameSettings(gameState),
              DesignTokens.sectionGap,
              _buildAboutSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const PanelHeader(
      emoji: '⚙️',
      title: 'Paramètres',
    );
  }

  Widget _buildEnterpriseSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              emoji: '🏢',
              title: 'Entreprise',
            ),
            DesignTokens.sectionGap,
            _buildInfoRow('Nom', gameState.enterpriseName),
            _buildInfoRow('ID', gameState.enterpriseId ?? 'Non défini'),
            _buildInfoRow(
              'Créée le',
              gameState.enterpriseCreatedAt?.toString().split(' ')[0] ?? 'Inconnu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = FirebaseAuthService.instance.currentUser;
    
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              emoji: '👤',
              title: 'Compte Google',
            ),
            DesignTokens.sectionGap,
            if (user != null) ...[
              _buildInfoRow('Email', user.email ?? 'Non disponible'),
              _buildInfoRow('UID', user.uid),
              DesignTokens.mediumGap,
              ActionButton(
                emoji: '🚪',
                label: 'Se déconnecter',
                onPressed: () async {
                  await FirebaseAuthService.instance.signOut();
                  if (mounted) {
                    setState(() {});
                  }
                },
                color: Colors.red,
              ),
            ] else ...[
              const Text('Non connecté'),
              const SizedBox(height: 8),
              const Text(
                'La connexion Google est gérée via les paramètres principaux',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettings(GameState gameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres de Jeu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sons'),
              subtitle: const Text('Activer les effets sonores'),
              value: true, // TODO: Lier à un vrai paramètre
              onChanged: (value) {
                // TODO: Implémenter
              },
            ),
            SwitchListTile(
              title: const Text('Musique'),
              subtitle: const Text('Activer la musique de fond'),
              value: true, // TODO: Lier à un vrai paramètre
              onChanged: (value) {
                // TODO: Implémenter
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Recevoir des notifications'),
              value: true, // TODO: Lier à un vrai paramètre
              onChanged: (value) {
                // TODO: Implémenter
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À propos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '2.0.0'),
            _buildInfoRow('Build', 'CHANTIER-06'),
            const SizedBox(height: 16),
            const Text(
              'PaperClip 2 - Idle Game\nArchitecture Entreprise Unique',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
