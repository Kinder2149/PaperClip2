import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../constants/game_config.dart'; // ImportÃ© depuis constants au lieu de models
import '../utils/update_manager.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../services/notification_manager.dart'; // Ajout de l'import pour NotificationManager
import '../services/navigation_service.dart';
import '../services/app_bootstrap_controller.dart';
import '../services/game_runtime_coordinator.dart';
import 'save_load_screen.dart';
import 'introduction_screen.dart';
import 'package:paperclip2/screens/main_screen.dart';
import '../services/google/google_bootstrap.dart';
import '../services/auth/jwt_auth_service.dart';
import '../services/persistence/local_game_persistence.dart';
import '../services/persistence/game_snapshot.dart';
import '../services/google/sync/sync_readiness_port.dart';
import '../services/google/identity/identity_status.dart';
import '../models/game_state.dart';
import '../services/google/identity/google_identity_service.dart';
import 'auth_choice_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/google/google_account_button.dart';
import 'google_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/services/cloud/http_cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/local_cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/snapshots_cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
// Cloud global GPG snapshots retiré (cloud par partie uniquement)

/// Implémentation minimale inline de SyncReadinessPort (top-level)
/// - Sync autorisée si l'utilisateur est connecté ET si l'opt-in est activé
/// - Vérification réseau simplifiée (toujours true pour le moment)
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

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isLoading = false;
  String? _lastSaveInfo;

  @override
  void initState() {
    super.initState();
    _loadLastSaveInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareCloudSessionSilently();
    });
  }

  // Flux Control Center (cloud global) supprimé

  Future<void> _prepareCloudSessionSilently() async {
    try {
      // Google-only: tentative silencieuse d'actualiser l'identité GPG
      final google = context.read<GoogleServicesBundle>();
      await google.identity.refresh();
    } catch (_) {}
  }

  Future<void> _refreshGpgStatus() async {
    try {
      final google = context.read<GoogleServicesBundle>();
      final before = google.identity.status;
      await google.identity.refresh();
      final after = google.identity.status;
      final pid = google.identity.playerId ?? '';
      debugPrint('[GPG] refresh() before=$before after=$after pid=$pid');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[GPG] refresh() error: $e');
    }
  }

  Future<void> _onAccountButtonPressed() async {
    final google = context.read<GoogleServicesBundle>();
    if (google.identity.status != IdentityStatus.signedIn) {
      // Connexion explicite si non connecté
      try {
        debugPrint('[AccountButton] signIn() demandé (état avant=${google.identity.status})');
        await google.identity.signIn();
        final newStatus = google.identity.status;
        final pid = google.identity.playerId ?? '';
        debugPrint('[AccountButton] signIn() terminé (état après=$newStatus, pid=$pid)');
        if (mounted) {
          if (newStatus == IdentityStatus.signedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connecté à Google Play Games')),
            );
            try {
              final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
              if (enableCloudPerPartie) {
                final enableHttp = (dotenv.env['FEATURE_CLOUD_PER_PARTIE_HTTP'] ?? 'false').toLowerCase() == 'true';
                if (enableHttp) {
                  final base = (dotenv.env['CLOUD_BACKEND_BASE_URL'] ?? '').trim();
                  if (base.isEmpty) {
                    GamePersistenceOrchestrator.instance.setCloudPort(LocalCloudPersistencePort());
                    // Fournir également le provider playerId à l'orchestrateur
                    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async {
                      return google.identity.playerId;
                    });
                  } else {
                    GamePersistenceOrchestrator.instance.setCloudPort(
                      HttpCloudPersistencePort(
                        baseUrl: base,
                        authHeaderProvider: () async {
                          // JWT dynamique si présent, sinon fallback API key via .env
                          final headers = await JwtAuthService.instance.buildAuthHeaders();
                          if (headers != null) return headers;
                          final bearer = (dotenv.env['CLOUD_API_BEARER'] ?? '').trim();
                          if (bearer.isEmpty) return null;
                          return {'Authorization': 'Bearer ' + bearer};
                        },
                        playerIdProvider: () async {
                          return google.identity.playerId;
                        },
                      ),
                    );
                    // Injecter aussi côté orchestrateur (auto-push dans la pompe)
                    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async {
                      return google.identity.playerId;
                    });
                    // Proactif: si playerId dispo, tenter d'obtenir un JWT maintenant
                    final pidNow = google.identity.playerId;
                    if (pidNow != null && pidNow.isNotEmpty) {
                      try { await JwtAuthService.instance.loginWithPlayerId(pidNow); } catch (_) {}
                    }
                  }
                } else {
                  GamePersistenceOrchestrator.instance.setCloudPort(SnapshotsCloudPersistencePort());
                  // Fournir également le provider playerId à l'orchestrateur
                  GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async {
                    return google.identity.playerId;
                  });
                }
                final playerId = google.identity.playerId;
                if (playerId != null && playerId.isNotEmpty) {
                  await GamePersistenceOrchestrator.instance.onPlayerConnected(playerId: playerId);
                }
              }
            } catch (_) {}
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connexion Google non effectuée')),
            );
          }
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connexion Google échouée: $e')),
          );
        }
      }
      return;
    }

    // Déjà connecté: afficher un menu simple d'actions liées au compte
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(builder: (context) {
                final google = context.read<GoogleServicesBundle>();
                final enableProfileUI =
                    (dotenv.env['FEATURE_PLAYER_PROFILE_UI'] ?? 'false')
                            .toLowerCase() ==
                        'true';
                final signedIn = google.identity.status == IdentityStatus.signedIn;
                final name = enableProfileUI ? (google.identity.displayName ?? '') : '';
                final url = enableProfileUI ? (google.identity.avatarUrl ?? '') : '';
                if (!enableProfileUI || !signedIn || (name.isEmpty && url.isEmpty)) {
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
                          MaterialPageRoute(builder: (_) => const GoogleProfileScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
              
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Se déconnecter de Google'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await google.identity.signOut();
                    if (mounted) {
                      debugPrint('[AccountButton] Déconnexion effectuée');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Déconnecté de Google Play Games')),
                      );
                      setState(() {});
                    }
                  } catch (e) {
                    if (mounted) {
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
  }

  Future<void> _saveCloudForGooglePlayer() async {
    try {
      final google = context.read<GoogleServicesBundle>();
      final pid = google.identity.playerId;
      if (pid == null || pid.isEmpty) {
        throw StateError('Aucun playerId Google');
      }
      final state = context.read<GameState>();
      final saveName = 'cloud_$pid';
      await GamePersistenceOrchestrator.instance.saveGame(state, saveName);

      // Cloud global GPG supprimé: cloud-first par partie uniquement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde liée au compte enregistrée ($saveName)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _restoreCloudForGooglePlayer() async {
    try {
      final google = context.read<GoogleServicesBundle>();
      final pid = google.identity.playerId;
      if (pid == null || pid.isEmpty) {
        throw StateError('Aucun playerId Google');
      }
      // Mission 4 (Cloud passif, ID-first):
      // Ne pas créer/charger de partie par un nom synthétique (cloud_$playerId).
      // La restauration cloud doit être initiée par partie existante (partieId)
      // depuis l'écran Sauvegardes via push/pull par ID.
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Restauration cloud par partie uniquement. Ouvrez "Sauvegardes" et utilisez Pull par ID.',
          level: NotificationLevel.INFO,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la restauration: $e')),
        );
      }
    }
  }

  Future<void> _loadLastSaveInfo() async {
    final lastSave = await GamePersistenceOrchestrator.instance.getLastSave();
    if (lastSave != null) {
      setState(() {
        _lastSaveInfo = 'DerniÃ¨re partie : ${lastSave.name}';
      });
    }
  }


  Future<void> _continueLastGame() async {
    setState(() => _isLoading = true);
    try {
      // Boot dÃ©terministe: attendre que l'application soit prÃªte.
      await context.read<AppBootstrapController>().waitUntilReady();

      final lastSave = await GamePersistenceOrchestrator.instance.getLastSave();
      if (lastSave != null) {
        // PHASE 2: ID-first pour la reprise de la dernière partie
        await context
            .read<GameRuntimeCoordinator>()
            .loadGameByIdAndStartAutoSave(lastSave.id);
        
        if (mounted) {
          // Naviguer vers l'Ã©cran principal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          NotificationManager.instance.showNotification(
            message: 'Aucune sauvegarde trouvÃ©e',
            level: NotificationLevel.INFO,
            duration: const Duration(seconds: 1),
          );
        }
      }
    } catch (e) {
      print('Erreur dans _continueLastGame: $e');
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Erreur lors du chargement de la sauvegarde: $e',
          level: NotificationLevel.ERROR,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewGameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    // Variable pour suivre le mode sÃ©lectionnÃ©
    GameMode selectedMode = GameMode.INFINITE;
    // Choix explicite du mode de sauvegarde
    String selectedStorage = 'local'; // 'local' | 'cloud'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle Partie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la partie',
                    hintText: 'Entrez un nom pour votre partie',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mode de jeu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Option pour le mode infini
                RadioListTile<GameMode>(
                  title: const Text('Mode Infini'),
                  subtitle: const Text('Jouez sans limites Ã  votre rythme'),
                  value: GameMode.INFINITE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),

                // Option pour le mode compÃ©titif
                RadioListTile<GameMode>(
                  title: const Text('Mode CompÃ©titif'),
                  subtitle: const Text('Obtenez le meilleur score avant la crise'),
                  value: GameMode.COMPETITIVE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),

                if (selectedMode == GameMode.COMPETITIVE)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ðŸ† Mode CompÃ©titif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Optimisez votre production jusqu Ã  la crise mondiale de mÃ©tal pour obtenir le meilleur score. Comparez vos rÃ©sultats avec vos amis !',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                const Text(
                  'Mode de sauvegarde',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Sauvegarde locale'),
                  value: 'local',
                  groupValue: selectedStorage,
                  onChanged: (v) => setState(() => selectedStorage = v!),
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),
                RadioListTile<String>(
                  title: const Text('Sauvegarde cloud (Google Play Games)'),
                  subtitle: const Text('Nécessite la connexion à Google Play Games'),
                  value: 'cloud',
                  groupValue: selectedStorage,
                  onChanged: (v) => setState(() => selectedStorage = v!),
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cette action crÃ©era une nouvelle sauvegarde',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final gameName = controller.text.trim();
                if (gameName.isEmpty) {
                  NotificationManager.instance.showNotification(
                    message: 'Le nom ne peut pas Ãªtre vide',
                    level: NotificationLevel.INFO,
                    duration: const Duration(seconds: 1),
                  );
                  return;
                }

                // ID-first: le nom est cosmétique, aucune vérification d'unicité par nom

                if (context.mounted) {
                  // D'abord activer le chargement dans l'Ã©tat de l'Ã©cran de dÃ©marrage avant de fermer le dialogue
                  this.setState(() => _isLoading = true);
                  // Ensuite fermer le dialogue
                  Navigator.pop(context);
                  try {
                    // Enregistrer le mode de sauvegarde choisi dans le GameState
                    final gs = context.read<GameState>();
                    gs.setStorageMode(selectedStorage);
                    // Utiliser le mode sÃ©lectionnÃ© lors de la crÃ©ation
                    await context
                        .read<GameRuntimeCoordinator>()
                        .startNewGameAndStartAutoSave(gameName, mode: selectedMode);

                    // Déclencher automatiquement un push cloud initial si joueur connecté et cloud par partie activé
                    try {
                      final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
                      if (enableCloudPerPartie) {
                        final google = context.read<GoogleServicesBundle>();
                        final signedIn = google.identity.status == IdentityStatus.signedIn;
                        final playerId = google.identity.playerId;
                        final gs = context.read<GameState>();
                        final partieId = gs.partieId ?? '';
                        if (signedIn && (playerId != null && playerId.isNotEmpty) && partieId.isNotEmpty) {
                          try {
                            await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(
                              partieId: partieId,
                              playerId: playerId,
                            );
                          } catch (e) {
                            // Marquer l'état "pending" pour retry ultérieur et informer discrètement
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('pending_cloud_push_'+partieId, true);
                            } catch (_) {}
                            if (context.mounted) {
                              NotificationManager.instance.showNotification(
                                message: 'Échec de synchronisation cloud: une resynchronisation est nécessaire (réseau ou service indisponible).',
                                level: NotificationLevel.ERROR,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          }
                        }
                      }
                    } catch (_) {}

                    if (context.mounted) {
                      // Tentative GPG supprimée (cloud global)
                      // CrÃ©er une classe intermÃ©diaire pour la navigation
                      final introScreen = IntroductionScreen(
                        showSkipButton: true,
                        isCompetitiveMode: selectedMode == GameMode.COMPETITIVE,
                        onStart: () {
                          context.read<NavigationService>().pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainScreen()),
                          );
                        },
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => introScreen),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      NotificationManager.instance.showNotification(
                        message: 'Erreur lors de la crÃ©ation: $e',
                        level: NotificationLevel.ERROR,
                      );
                    }
                  } finally {
                    if (mounted) {
                      // S'assurer que nous modifions l'Ã©tat de l'Ã©cran de dÃ©marrage, pas du dialogue
                      this.setState(() => _isLoading = false);
                    }
                  }
                }
              },
              child: const Text('Commencer'),
            ),
          ],
        ),
      ),
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
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                // Logo et titre (inchangÃ©s)
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
                  onPressed: () => _showNewGameDialog(context),
                  icon: Icons.add,
                  label: 'Nouvelle Partie',
                  color: Colors.white,
                  textColor: Colors.deepPurple[700],
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  onPressed: _isLoading ? null : _continueLastGame,
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
                    child: Text(
                      _lastSaveInfo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  )
                      : null,
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  onPressed: _isLoading ? null : () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SaveLoadScreen()),
                      ),
                  icon: Icons.folder_open,
                  label: 'Charger une partie',
                  color: Colors.deepPurple[500],
                  textColor: Colors.white,
                ),

                const SizedBox(height: 16),

                // Bouton compte Google (réutilisable, consomme uniquement l'identité)
                GoogleAccountButton(
                  onPressed: _isLoading ? null : _onAccountButtonPressed,
                  backgroundColor: Colors.deepPurple[400],
                  textColor: Colors.white,
                  showAvatar: true,
                ),

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
                        ],
                      ),
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