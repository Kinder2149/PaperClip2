// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Import de notre nouvelle AppBar
import '../widgets/appbar/game_appbar.dart';

// Imports des modèles
import '../models/game_state.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../models/event_system.dart';
import '../models/progression_system.dart';
import '../models/statistics_manager.dart';
import '../models/level_system.dart';

import '../services/notification_manager.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';

// Imports des services
import '../services/background_music.dart';
import '../services/game_runtime_coordinator.dart';

// Imports des widgets
import '../widgets/indicators/notification_widgets.dart';
import '../widgets/save_button.dart';

// Imports des écrans
import 'production_screen.dart';
import 'market_screen.dart';
import 'upgrades_screen.dart';
import 'event_log_screen.dart';
import 'save_load_screen.dart';
import 'start_screen.dart';
import 'new_metal_production_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  BackgroundMusicService? _backgroundMusicService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GameRuntimeCoordinator>().startSession();
    });
    // Corriger l'ordre des écrans
    _screens = [
      const ProductionScreen(),
      const MarketScreen(), // Index 1
      const UpgradesScreen(), // Index 2
    ];
    // Retirer PlaceholderLockedScreen de la liste initiale
    _initializeGame();
    _playBackgroundMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundMusicService ??= context.read<BackgroundMusicService>();
  }

  Future<void> _initializeGame() async {
    final gameState = context.read<GameState>();
    await Future.delayed(Duration.zero);
    
    // Activer la musique par défaut
    await _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    final backgroundMusicService = context.read<BackgroundMusicService>();
    await backgroundMusicService.initialize();
    await backgroundMusicService.play();
  }

  Future<void> _toggleMusic() async {
    final backgroundMusicService = context.read<BackgroundMusicService>();
    if (backgroundMusicService.isPlaying) {
      await backgroundMusicService.pause();
    } else {
      await backgroundMusicService.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _backgroundMusicService?.dispose();
    super.dispose();
  }

  String _formatTimePlayed(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  Widget _getCurrentScreen(VisibleUiElements visibleScreens) {
    switch (_selectedIndex) {
      case 0:
        return _screens[0]; // Production toujours visible
      case 1:
        return visibleScreens[UiElement.market] == true
            ? _screens[1]
            : const PlaceholderLockedScreen();
      case 2:
        return visibleScreens[UiElement.upgradesSection] == true
            ? _screens[2]
            : const PlaceholderLockedScreen();
      default:
        return _screens[0];
    }
  }

  List<NavigationDestination> _buildNavigationDestinations(
      VisibleUiElements visibleScreens) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.factory_outlined),
        selectedIcon: Icon(Icons.factory),
        label: 'Production',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens[UiElement.market] == true
            ? Icons.shopping_cart_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens[UiElement.market] == true
            ? Icons.shopping_cart
            : Icons.lock),
        label: visibleScreens[UiElement.market] == true
            ? 'Marché'
            : 'Niveau ${GameConstants.MARKET_UNLOCK_LEVEL}',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens[UiElement.upgradesSection] == true
            ? Icons.upgrade_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens[UiElement.upgradesSection] == true
            ? Icons.upgrade
            : Icons.lock),
        label: visibleScreens[UiElement.upgradesSection] == true
            ? 'Améliorations'
            : 'Niveau ${GameConstants.UPGRADES_UNLOCK_LEVEL}',
      ),
    ];
  }

  // Méthode _saveGame supprimée car remplacée par SaveButton.saveGame

  void _showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Niveau ${levelSystem.level}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP: ${levelSystem.experience}/${levelSystem
                    .experienceForNextLevel}'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: levelSystem.experienceProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Multiplicateur: x${levelSystem.productionMultiplier
                    .toStringAsFixed(1)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  String _getLastSaveTimeText(GameState gameState) {
    final lastSave = gameState.lastSaveTime;
    if (lastSave == null) return 'Jamais';

    final now = DateTime.now();
    final difference = now.difference(lastSave);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    }
    return '${lastSave.day}/${lastSave.month} ${lastSave.hour}:${lastSave.minute}';
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Selector<GameState, StatisticsManager>(
                  selector: (context, gameState) => gameState.statistics,
                  builder: (context, statistics, _) {
                    return AnimatedBuilder(
                      animation: statistics,
                      builder: (context, child) {
                        final stats = statistics.getAllStats();
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildStatSection('Production', stats['production']!),
                              const SizedBox(height: 16),
                              _buildStatSection('Économie', stats['economy']!),
                              const SizedBox(height: 16),
                              _buildStatSection('Progression', stats['progression']!),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            ...stats.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAboutInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            const Text('À propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${GameConstants.VERSION}'),
            const SizedBox(height: 8),
            const Text('Un jeu incrémental de production de trombones.'),
            const SizedBox(height: 16),
            const Text('Fonctionnalités:'),
            const Text('• Production de trombones'),
            const Text('• Gestion du marché'),
            const Text('• Système d\'améliorations'),
            const Text('• Événements dynamiques'),
            const SizedBox(height: 16),
            const Text('Développé avec ❤️ par Kinder2149'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final backgroundMusicService = context.watch<BackgroundMusicService>();

        // Utilisation de notre nouvelle GameAppBar réutilisable
        final appBar = PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: GameAppBar(
            selectedIndex: _selectedIndex,
            onSettingsPressed: () => _showSettingsMenu(context),
          ),
        );

        // Construction du contenu selon le mode
        if (gameState.isInCrisisMode) {
          return Scaffold(
            appBar: appBar,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: gameState.crisisTransitionComplete
                  ? Stack(
                children: [
                  gameState.showingCrisisView
                      ? const NewMetalProductionScreen()
                      : _getCurrentScreen(gameState.getVisibleUiElements()),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red.withOpacity(0.9),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Mode Crise Actif',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : const NewMetalProductionScreen(),
            ),
            bottomNavigationBar: gameState.crisisTransitionComplete
                ? SafeArea(
              child: NavigationBar(
                height: 56,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: _buildNavigationDestinations(
                    gameState.getVisibleUiElements()
                ),
              ),
            )
                : null,
            floatingActionButton: FloatingActionButton(
              onPressed: () => gameState.toggleCrisisInterface(),
              backgroundColor: gameState.crisisTransitionComplete
                  ? Colors.deepPurple
                  : Colors.blue,
              child: Icon(
                gameState.showingCrisisView
                    ? Icons.shopping_cart
                    : Icons.factory,
                color: Colors.white,
              ),
            ),
          );
        }

        // Interface normale
        final visibleScreens = gameState.getVisibleUiElements();
        final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
        final metalPerPaperclip = UpgradeEffectsCalculator.metalPerPaperclip(
          efficiencyLevel: efficiencyLevel,
        );
        final canProduce = gameState.player.metal >= metalPerPaperclip;

        return Scaffold(
          appBar: appBar,
          body: Stack(
            children: [
              _getCurrentScreen(visibleScreens),
              Consumer<EventManager>(
                builder: (context, eventManager, _) {
                  final notification = eventManager.notificationStream.value;
                  if (notification == null) return const SizedBox.shrink();
                  return AnimatedNotificationOverlay(
                    event: notification,
                    onDismiss: () {
                      eventManager.notificationStream.value = null;
                    },
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!gameState.isInCrisisMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canProduce
                                ? () {
                              HapticFeedback.mediumImpact();
                              gameState.producePaperclip();
                            }
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: canProduce
                                    ? Colors.blue.shade400
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: canProduce
                                      ? Colors.blue.shade200
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: canProduce
                                    ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: canProduce ? Colors.white : Colors
                                        .grey.shade300,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        'Produire',
                                        style: TextStyle(
                                          color: canProduce
                                              ? Colors.white
                                              : Colors.grey.shade300,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${metalPerPaperclip.toStringAsFixed(2)} métal',
                                        style: TextStyle(
                                          color: canProduce
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.grey.shade300,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  NavigationBar(
                    height: 56,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                    destinations: _buildNavigationDestinations(visibleScreens),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Production';
      case 1:
        return 'Marché';
      case 2:
        return 'Améliorations';
      default:
        return 'PaperClip Game';
    }
  }

  Widget _buildLevelIndicator(LevelSystem levelSystem) {
    return GestureDetector(
      onTap: () => _showLevelInfoDialog(context, levelSystem),
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            ),
            Text(
              '${levelSystem.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return ValueListenableBuilder<int>(
      valueListenable: EventManager.instance.unreadCount,
      builder: (context, unreadCount, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EventLogScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final gameState = context.read<GameState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de glissement
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // En-tête
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.settings, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Paramètres',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Section Informations
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: ExpansionTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Informations'),
                        initiallyExpanded: true,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.timer_outlined),
                            title: const Text('Temps de jeu'),
                            subtitle: Text(gameState.formattedPlayTime),
                          ),
                          ListTile(
                            leading: const Icon(Icons.stars_outlined),
                            title: const Text('Niveau'),
                            subtitle: Text('${gameState.level.level}'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: const Text('Trombones produits'),
                            subtitle: Row(
                              children: [
                                Text('${gameState.totalPaperclipsProduced} / ${GameConstants.GLOBAL_PROGRESS_TARGET.toStringAsFixed(0)}'),
                                const SizedBox(width: 8),
                                _buildProgressIndicator(context, gameState),
                              ],
                            ),
                            onTap: () => _showProgressDetails(context, gameState),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nouvelle section Statistiques
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: ListTile(
                        leading: const Icon(Icons.analytics),
                        title: const Text('Statistiques'),
                        subtitle: const Text(
                            'Voir les statistiques détaillées'),
                        onTap: () => _showStatistics(context),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Section Sauvegarde
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.save),
                            title: const Text('Sauvegarder'),
                            subtitle: Text(
                              'Dernière sauvegarde: ${_getLastSaveTimeText(
                                  gameState)}',
                            ),
                            onTap: () {
                              // Fermer le modal pour voir le feedback de sauvegarde
                              Navigator.pop(context);
                              // Utiliser le widget SaveButton pour déclencher la sauvegarde
                              SaveButton.saveGame(context);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.folder_open),
                            title: const Text('Charger une partie'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (
                                      context) => const SaveLoadScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.home),
                            title: const Text('Retour au menu principal'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const StartScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.refresh),
                            title: const Text('Nouvelle partie'),
                            onTap: () => _showNewGameConfirmation(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Section Audio
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: Consumer<BackgroundMusicService>(
                        builder: (context, musicService, _) =>
                            SwitchListTile(
                              secondary: Icon(
                                musicService.isPlaying
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                              ),
                              title: const Text('Musique'),
                              value: musicService.isPlaying,
                              onChanged: (value) => _toggleMusic(),
                            ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    
                    // Section Services de jeu
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.games),
                            title: const Text('Mode hors ligne'),
                            subtitle: const Text('Les scores sont stockés localement'),
                            onTap: () async {
                              if (context.mounted) {
                                NotificationManager.instance.showNotification(
                                  message: 'Application en mode hors ligne - Scores stockés localement',
                                  level: NotificationLevel.INFO,
                                  duration: const Duration(seconds: 2),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Section À propos
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: Text(
                                'Version ${GameConstants.VERSION}'),
                            onTap: () => _showAboutInfo(context),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start,
                              children: [
                                Text('${GameConstants.APP_NAME}'),
                                const SizedBox(height: 8),
                                const Text(
                                    'Un jeu de gestion incrémentale de production de trombones.'),
                                const SizedBox(height: 8),
                                const Text(
                                    'Développé avec ❤️ par Kinder2149'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour afficher la confirmation de nouvelle partie
  void _showNewGameConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning),
            SizedBox(width: 8),
            Text('Nouvelle partie'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir démarrer une nouvelle partie ?'),
            SizedBox(height: 8),
            Text('La progression de la partie actuelle sera perdue si elle n\'est pas sauvegardée.',
                 style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context); // Fermer les paramètres
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const StartScreen(),
                ),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Nouvelle partie'),
          ),
        ],
      ),
    );
  }

  // Méthode pour la gestion de la sauvegarde
  // Construit l'indicateur de progression pour la vue dans les paramètres
  Widget _buildProgressIndicator(BuildContext context, GameState gameState) {
    // Calcul du progrès global
    final double progressValue = _calculateGlobalProgress(gameState);
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.blue.shade900
            : Colors.blue.shade700,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: progressValue,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progressValue, Theme.of(context).brightness)
              ),
              strokeWidth: 2,
            ),
          ),
          Text(
            '${(progressValue * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Calcul de la progression globale du jeu
  double _calculateGlobalProgress(GameState gameState) {
    // Version simple: basée sur le nombre de trombones produits par rapport à un objectif
    double maxPaperclips = GameConstants.GLOBAL_PROGRESS_TARGET;
    double currentPaperclips = gameState.player.totalPaperclips;
    
    // Limiter à 1.0 (100%)
    return (currentPaperclips / maxPaperclips).clamp(0.0, 1.0);
  }

  // Couleurs selon le pourcentage de progression
  Color _getProgressColor(double progress, Brightness brightness) {
    if (progress < 0.3) {
      return brightness == Brightness.dark ? Colors.redAccent : Colors.red;
    } else if (progress < 0.6) {
      return brightness == Brightness.dark ? Colors.amberAccent : Colors.amber;
    } else {
      return brightness == Brightness.dark ? Colors.greenAccent : Colors.green;
    }
  }

  // Affichage des détails de progression
  void _showProgressDetails(BuildContext context, GameState gameState) {
    final progress = _calculateGlobalProgress(gameState);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.insights),
            SizedBox(width: 8),
            Text('Progression Globale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progression: ${(progress * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text(
              'Trombones produits: ${gameState.player.totalPaperclips.toStringAsFixed(0)} / ${GameConstants.GLOBAL_PROGRESS_TARGET.toStringAsFixed(0)}'
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress, Theme.of(context).brightness)
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Continuez à produire des trombones pour progresser dans le jeu!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Méthode _handleSave supprimée car remplacée par SaveButton.saveGame
}

class PlaceholderLockedScreen extends StatelessWidget {
  const PlaceholderLockedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Débloqué au niveau 7',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}