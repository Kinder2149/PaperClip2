import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'package:paperclip2/core/constants/constantes.dart';
import '../utils/update_manager.dart';
import '../services/notification_manager.dart'; // Ajout de l'import pour NotificationManager
import '../services/navigation_service.dart';
import '../services/app_bootstrap_controller.dart';
import 'introduction_screen.dart';
import 'package:paperclip2/screens/main_screen.dart';
import '../services/google/google_bootstrap.dart';
import '../services/google/identity/identity_status.dart';
import '../models/game_state.dart';
import '../services/google/identity/google_identity_service.dart';
import 'auth_choice_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/google/google_account_button.dart';
import '../widgets/google/account_info_card.dart';
import '../widgets/sync_status_chip.dart';
import 'profile_screen.dart';
// Cloud global GPG snapshots retiré (cloud par partie uniquement)
import 'package:paperclip2/services/runtime/runtime_actions.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import '../utils/logger.dart';
import '../widgets/appbar/settings_bottom_sheet.dart';

// Classe de readiness cloud supprimée (non utilisée)

class StartScreen extends StatefulWidget {
  final bool continueOpensWorlds;
  const StartScreen({super.key, this.continueOpensWorlds = false});
  // Flag de test pour neutraliser le wiring silencieux (évite microtasks/timers en tests)
  static bool testingDisableSilentWiring = false;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final Logger _logger = Logger.forComponent('ui-start');

  bool _isLoading = false;
  String? _lastSaveInfo;
  String? _lastSaveCanonicalLabel;
  bool _hasLastSave = false;

  @override
  void initState() {
    super.initState();
    _loadLastSaveInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Suppression du wiring silencieux cloud: aucune association implicite ici
    });
  }

  // Flux Control Center (cloud global) supprimé

  // Wiring cloud supprimé: aucune association automatique de playerId ou port cloud depuis le StartScreen

  Future<void> _refreshGpgStatus() async {
    try {
      final google = context.read<GoogleServicesBundle>();
      final before = google.identity.status;
      await google.identity.refresh();
      final after = google.identity.status;
      final pid = google.identity.playerId ?? '';
      if (kDebugMode) _logger.debug('[GPG] refresh() before=$before after=$after pid=$pid');
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) _logger.debug('[GPG] refresh() error: $e');
    }
  }

  Future<void> _onAccountButtonPressed() async {
    // OPTION A: Firebase = source de vérité pour l'état connecté
    final firebaseUser = FirebaseAuthService.instance.currentUser;
    
    if (firebaseUser == null) {
      // Pas connecté Firebase → Connexion Firebase + GPG (best effort)
      await _signIn();
      return;
    }

    // Déjà connecté Firebase → Afficher menu utilisateur
    if (kDebugMode) _logger.debug('[AccountButton] Firebase connecté (uid=${firebaseUser.uid}) - Menu');
    if (!mounted) return;
    _showAccountMenu();
  }

  /// Connexion Firebase + tentative GPG (best effort)
  Future<void> _signIn() async {
    try {
      if (kDebugMode) _logger.debug('[SignIn] Connexion Firebase demandée');
      
      // 1. Connexion Firebase (OBLIGATOIRE)
      await FirebaseAuthService.instance.signInWithGoogle();
      
      // 2. Tentative GPG (OPTIONNEL, best effort)
      try {
        final google = context.read<GoogleServicesBundle>();
        await google.identity.signIn();
        if (kDebugMode) _logger.debug('[SignIn] GPG connecté avec succès');
      } catch (e) {
        // Échec GPG non bloquant
        if (kDebugMode) _logger.debug('[SignIn] GPG échec (non bloquant): $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecté avec succès'))
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion échouée: $e'))
        );
      }
    }
  }

  /// Affiche le menu utilisateur (déjà connecté Firebase)
  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option 1: Profil GPG (si disponible)
              Builder(builder: (context) {
                final google = context.read<GoogleServicesBundle>();
                final enableProfileUI =
                    (dotenv.env['FEATURE_PLAYER_PROFILE_UI'] ?? 'false').toLowerCase() == 'true';
                final isGpgReady = google.identity.status.toString().contains('authenticated');
                
                if (!enableProfileUI || !isGpgReady) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Voir mon profil'),
                      onTap: () async {
                        Navigator.pop(context);
                        if (!mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
              
              // Option 2: Paramètres
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                  if (!mounted) return;
                  showSettingsBottomSheet(context);
                },
              ),
              const Divider(height: 1),
              
              // Option 3: Déconnexion
              Builder(builder: (context) {
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Se déconnecter'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _signOut();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Déconnexion Firebase + GPG (best effort)
  Future<void> _signOut() async {
    try {
      // 1. Déconnexion Firebase
      await FirebaseAuthService.instance.signOut();
      
      // 2. Déconnexion GPG (best effort)
      try {
        final google = context.read<GoogleServicesBundle>();
        await google.identity.signOut();
      } catch (e) {
        if (kDebugMode) _logger.debug('[SignOut] GPG échec (non bloquant): $e');
      }
      
      if (mounted) {
        if (kDebugMode) _logger.debug('[SignOut] Déconnexion effectuée');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnecté'))
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur déconnexion: $e'))
        );
      }
    }
  }

  Future<void> _loadLastSaveInfo() async {
    // SavesFacade supprimé - utilisation directe LocalSaveGameManager
    try {
      final mgr = await LocalSaveGameManager.getInstance();
      final allMeta = await mgr.listSaves();
      if (allMeta.isEmpty) {
        setState(() {
          _hasLastSave = false;
        });
        return;
      }
      // Trier par date et prendre le plus récent
      allMeta.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final lastSave = await mgr.loadSave(allMeta.first.id);
      if (lastSave != null) {
        setState(() {
          _lastSaveInfo = 'Dernier monde : ${lastSave.name}';
          _lastSaveCanonicalLabel = 'Disponible';
          _hasLastSave = true;
        });
      } else {
        setState(() {
          _hasLastSave = false;
        });
      }
    } catch (_) {
      setState(() {
        _hasLastSave = false;
      });
    }
  }

  Future<void> _continueLastGame() async {
    // Neutralisé: la reprise directe est désactivée (entrée unique via Mes Mondes)
    if (mounted) {
      NotificationManager.instance.showNotification(
        message: 'Ouvrez "Mes Mondes" pour sélectionner un monde',
        level: NotificationLevel.INFO,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _startNewGameAuto() async {
    // Neutralisé: la création de partie est désactivée (entrée unique via Mes Mondes)
    if (mounted) {
      NotificationManager.instance.showNotification(
        message: 'Créez un monde depuis "Mes Mondes"',
        level: NotificationLevel.INFO,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<String?> _showNewGameDialog({
    required BuildContext context,
    required String initialName,
  }) async {
    final TextEditingController nameController = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nouveau monde'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du monde',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim().isEmpty
                    ? PartieNaming.defaultName()
                    : nameController.text.trim();
                Navigator.of(ctx).pop(name);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[400]!,
              Colors.deepPurple[800]!,
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                // Logo et titre (inchangé)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.link,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ClipFactory Empire',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'v${UpdateManager.CURRENT_VERSION}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Boutons du menu (avec ajouts pour le cloud)
                _buildMenuButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => IntroductionScreen(
                                  onStart: () async {
                                    // Navigation vers MainScreen après création
                                    if (!context.mounted) return;
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const MainScreen()),
                                    );
                                  },
                                  onCreateEnterprise: (String enterpriseName) async {
                                    // Créer l'entreprise via RuntimeActions
                                    final runtimeActions = context.read<RuntimeActions>();
                                    await runtimeActions.createNewEnterpriseAndStartAutoSave(enterpriseName);
                                    runtimeActions.startSession();
                                  },
                                )),
                          ),
                  icon: Icons.add,
                  label: 'Créer une entreprise',
                  color: Colors.white,
                  textColor: Colors.deepPurple[700],
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  onPressed: _isLoading || !_hasLastSave
                      ? null
                      : () async {
                          // Charger la dernière entreprise
                          final mgr = await LocalSaveGameManager.getInstance();
                          final saves = await mgr.listSaves();
                          if (saves.isEmpty) return;
                          
                          final lastSave = saves.first;
                          if (!context.mounted) return;
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MainScreen()),
                          );
                        },
                  icon: Icons.play_arrow,
                  label: 'Continuer',
                  color: Colors.deepPurple[600],
                  textColor: Colors.white,
                  trailing: _lastSaveInfo != null
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _lastSaveInfo!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (_lastSaveCanonicalLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              _lastSaveCanonicalLabel!,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                      : null,
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  onPressed: _isLoading ? null : () => showSettingsBottomSheet(context),
                  icon: Icons.settings,
                  label: 'Paramètres',
                  color: Colors.white.withOpacity(0.15),
                  textColor: Colors.white,
                ),

                const SizedBox(height: 24),

                // Card élégante avec informations de compte et stats
                AccountInfoCard(
                  onTap: _isLoading ? null : _onAccountButtonPressed,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  textColor: Colors.white,
                ),

                const SizedBox(height: 16),

                // Indicateur discret d'état de synchronisation (non bloquant)
                const SyncStatusChip(),

                const SizedBox(height: 8),
                if (kDebugMode)
                  Builder(builder: (context) {
                    final google = context.watch<GoogleServicesBundle>();
                    final status = google.identity.status;
                    return Text(
                      'État GPG (debug): ${status.name}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  }),

                const SizedBox(height: 8),
                if (kDebugMode)
                  TextButton(
                    onPressed: _refreshGpgStatus,
                    child: const Text('Rafraîchir état GPG'),
                  ),

                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chargement...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

  }


  Widget _buildMenuButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color? color,
    required Color? textColor,
    Widget? trailing,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: onPressed != null ? 3 : 0,
          disabledBackgroundColor: color?.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) Flexible(child: trailing!),
          ],
        ),
      ),
    );
  }
}
