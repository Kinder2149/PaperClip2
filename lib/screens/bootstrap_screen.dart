import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/game_config.dart';
import '../models/game_state.dart';
import '../services/app_bootstrap_controller.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../services/runtime/runtime_actions.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({Key? key}) : super(key: key);

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔥🔥🔥 [BootstrapScreen] initState() called 🔥🔥🔥');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      print('🔥🔥🔥 [BootstrapScreen] didChangeDependencies() called, _started=$_started 🔥🔥🔥');
    }
    
    if (_started) return;
    _started = true;

    if (kDebugMode) {
      print('🔥🔥🔥 [BootstrapScreen] Scheduling bootstrap via postFrameCallback 🔥🔥🔥');
    }

    // Démarre le bootstrap après la première construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('🔥🔥🔥 [BootstrapScreen] postFrameCallback executing 🔥🔥🔥');
      }
      
      try {
        final bootstrap = context.read<AppBootstrapController>();
        if (kDebugMode) {
          print('🔥🔥🔥 [BootstrapScreen] Got AppBootstrapController, calling bootstrap() 🔥🔥🔥');
        }
        bootstrap.bootstrap();
      } catch (e, st) {
        if (kDebugMode) {
          print('🔥🔥🔥 [BootstrapScreen] ERROR getting bootstrap controller: $e 🔥🔥🔥');
          print('Stack: $st');
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant BootstrapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppBootstrapController>(
      builder: (context, bootstrap, _) {
        if (kDebugMode) {
          print('[BootstrapScreen] Build - Status: ${bootstrap.status}, isReady: ${bootstrap.isReady}, isSyncing: ${bootstrap.isSyncing}');
        }
        
        // Afficher loading UI si sync en cours
        if (bootstrap.isSyncing) {
          if (kDebugMode) {
            print('[BootstrapScreen] Displaying sync loading UI - sync in progress');
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Synchronisation cloud...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (bootstrap.isReady && !bootstrap.isSyncing) {
          if (kDebugMode) {
            print('[BootstrapScreen] Bootstrap ready AND sync completed, scheduling navigation...');
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            
            // Double-check que sync est terminée (éviter race condition)
            final bootstrapController = context.read<AppBootstrapController>();
            if (bootstrapController.isSyncing) {
              if (kDebugMode) {
                print('[BootstrapScreen] Navigation blocked - sync in progress');
              }
              return;
            }
            
            if (kDebugMode) {
              print('[BootstrapScreen] Navigation allowed - sync completed');
            }
            
            // CHANTIER-01: Navigation entreprise unique
            try {
              final gameState = context.read<GameState>();
              
              // Vérifier si une entreprise est déjà chargée en mémoire
              if (gameState.enterpriseId != null && gameState.enterpriseId!.isNotEmpty) {
                if (kDebugMode) {
                  print('[BootstrapScreen] Entreprise déjà chargée (ID: ${gameState.enterpriseId}), navigation MainScreen');
                }
                
                final runtimeActions = context.read<RuntimeActions>();
                runtimeActions.startSession();
                
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
                return;
              }
              
              // Vérifier si une entreprise existe localement (synchronisée depuis le cloud)
              final orchestrator = GamePersistenceOrchestrator.instance;
              final availableEnterprises = await orchestrator.listSaves();
              
              if (availableEnterprises.isNotEmpty) {
                // Filtrer les backups
                final nonBackupEnterprises = availableEnterprises
                    .where((meta) => !meta.name.contains(GameConstants.BACKUP_DELIMITER))
                    .toList();
                
                if (nonBackupEnterprises.isNotEmpty) {
                  if (kDebugMode) {
                    print('[BootstrapScreen] Entreprise disponible trouvée, chargement...');
                  }

                  // Charger la première entreprise disponible via son ID explicite
                  final enterpriseId = nonBackupEnterprises.first.id;
                  final runtimeActions = context.read<RuntimeActions>();
                  await runtimeActions.loadGameByIdAndStartAutoSave(enterpriseId);
                  runtimeActions.startSession();
                  
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                  return;
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('[BootstrapScreen] Erreur chargement entreprise: $e');
              }
            }
            
            // Pas d'entreprise: naviguer vers WelcomeScreen (première utilisation)
            if (kDebugMode) {
              print('[BootstrapScreen] Aucune entreprise trouvée, affichage WelcomeScreen');
            }
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          });
        }

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      bootstrap.hasError
                          ? 'Erreur de démarrage'
                          : 'Initialisation…',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (bootstrap.currentStep != null)
                      Text(
                        bootstrap.currentStep!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    if (bootstrap.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${bootstrap.lastError}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          bootstrap.retry();
                        },
                        child: const Text('Réessayer'),
                      ),
                      if (kDebugMode && bootstrap.lastStackTrace != null) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          child: Text(
                            bootstrap.lastStackTrace.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
