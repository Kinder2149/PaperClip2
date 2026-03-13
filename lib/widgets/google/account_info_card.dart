import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';

/// Widget élégant affichant les informations du compte Google connecté
/// avec mise à jour dynamique et statistiques des mondes
class AccountInfoCard extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const AccountInfoCard({
    super.key,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<AccountInfoCard> createState() => _AccountInfoCardState();
}

class _AccountInfoCardState extends State<AccountInfoCard> {
  int _worldCount = 0;
  bool _loadingWorlds = false;

  @override
  void initState() {
    super.initState();
    _loadWorldCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger le nombre de mondes quand on revient sur l'écran
    _loadWorldCount();
  }

  Future<void> _loadWorldCount() async {
    if (!mounted) return;
    setState(() => _loadingWorlds = true);
    
    try {
      final entries = await SaveAggregator().listAll(context);
      if (!mounted) return;
      setState(() {
        _worldCount = entries.where((e) => !e.isBackup).length;
        _loadingWorlds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _worldCount = 0;
        _loadingWorlds = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état Firebase Auth pour mise à jour dynamique
    return StreamBuilder(
      stream: FirebaseAuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = FirebaseAuthService.instance.currentUser;
        
        if (user == null) {
          // Utilisateur non connecté : bouton de connexion
          return _buildSignInButton(context);
        }

        // Utilisateur connecté : afficher les infos
        return _buildAccountInfo(context, user);
      },
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? Colors.white.withOpacity(0.15);
    final txtColor = widget.textColor ?? Colors.white;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: txtColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: txtColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle,
                size: 32,
                color: txtColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Synchronisez vos mondes dans le cloud',
                    style: TextStyle(
                      fontSize: 13,
                      color: txtColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: txtColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(BuildContext context, dynamic user) {
    final google = context.watch<GoogleServicesBundle>();
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? Colors.white.withOpacity(0.15);
    final txtColor = widget.textColor ?? Colors.white;

    // OPTION A: Firebase = source de vérité, GPG = données cosmétiques
    // Vérifier si GPG est disponible et authentifié
    final isGpgReady = google.identity.status.toString().contains('authenticated');
    
    // Récupérer les infos avec fallback Firebase
    final displayName = isGpgReady && google.identity.displayName != null
        ? google.identity.displayName!
        : user.email?.split('@').first ?? 'Utilisateur';
    final avatarUrl = isGpgReady ? google.identity.avatarUrl : null;
    final email = user.email ?? '';
    
    // Indicateur si GPG non disponible
    final showGpgBadge = !isGpgReady;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header : Avatar + Nom
            Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: txtColor.withOpacity(0.1),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: txtColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Nom + Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: txtColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: txtColor.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showGpgBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Profil incomplet',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: txtColor.withOpacity(0.5),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Divider(
              color: txtColor.withOpacity(0.2),
              height: 1,
            ),
            
            const SizedBox(height: 16),
            
            // Stats : Nombre de mondes
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.public,
                    label: 'Mondes',
                    value: _loadingWorlds ? '...' : '$_worldCount',
                    color: Colors.blue,
                    txtColor: txtColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.cloud_done,
                    label: 'Cloud',
                    value: 'Actif',
                    color: Colors.green,
                    txtColor: txtColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color txtColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: txtColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: txtColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
