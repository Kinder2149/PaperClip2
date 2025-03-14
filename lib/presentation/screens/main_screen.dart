﻿import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/game_constants.dart';
import '../../data/datasources/local/save_datasource.dart';
import '../../domain/entities/event_system.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/progression.dart';
import '../../domain/services/background_music_service.dart';
import '../../domain/services/event_manager.dart';
import '../../presentation/widgets/chart_widgets.dart';
import '../../presentation/widgets/competitive_mode_indicator.dart';
import '../../presentation/widgets/level_widgets.dart';
import '../../presentation/widgets/notification_widgets.dart';
import '../../presentation/widgets/production_button.dart';
import '../../presentation/widgets/resource_widgets.dart';
import 'event_log_screen.dart';
import 'introduction_screen.dart';
import 'market_screen.dart';
import 'new_metal_production_screen.dart';  // Ã€ ajouter en haut
import 'production_screen.dart';
import 'save_load_screen.dart';
import 'start_screen.dart';
import 'upgrades_screen.dart';
import 'package:paperclip2/presentation/screens/statistics_screen.dart';
import 'package:paperclip2/services/cloud_save_manager.dart';
import 'package:paperclip2/services/games_services_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Corriger l'ordre des Ã©crans
    _screens = [
      const ProductionScreen(),
      const MarketScreen(), // Index 1
      const UpgradesScreen(), // Index 2
    ];
    // Retirer PlaceholderLockedScreen de la liste initiale
    _initializeGame();
    _playBackgroundMusic();
  }

  Future<void> _initializeGame() async {
    final gameState = context.read<GameState>();
    await Future.delayed(Duration.zero);
    gameState.setContext(context);

    // Initialiser les services de jeux
    final gamesServices = GamesServicesController())))));
    await gamesServices.initialize();
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
    final backgroundMusicService = context.read<BackgroundMusicService>();
    backgroundMusicService.dispose();
    super.dispose();
  }

  String _formatTimePlayed(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  Widget _getCurrentScreen(Map<String, bool> visibleScreens) {
    switch (_selectedIndex) {
      case 0:
        return _screens[0]; // Production toujours visible
      case 1:
        return visibleScreens['market'] == true
            ? _screens[1]
            : const PlaceholderLockedScreen();
      case 2:
        return visibleScreens['upgradesSection'] == true
            ? _screens[2]
            : const PlaceholderLockedScreen();
      default:
        return _screens[0];
    }
  }

  List<NavigationDestination> _buildNavigationDestinations(
      Map<String, bool> visibleScreens) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.factory_outlined),
        selectedIcon: Icon(Icons.factory),
        label: 'Production',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens['market'] == true
            ? Icons.shopping_cart_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens['market'] == true
            ? Icons.shopping_cart
            : Icons.lock),
        label: visibleScreens['market'] == true
            ? 'MarchÃ©'
            : 'Niveau ${GameConstants.MARKET_UNLOCK_LEVEL}',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens['upgradesSection'] == true
            ? Icons.upgrade_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens['upgradesSection'] == true
            ? Icons.upgrade
            : Icons.lock),
        label: visibleScreens['upgradesSection'] == true
            ? 'AmÃ©liorations'
            : 'Niveau ${GameConstants.UPGRADES_UNLOCK_LEVEL}',
      ),
    ];
  }

  Future<void> _saveGame(BuildContext context) async {
    final gameState = context.read<GameState>();
    if (!gameState.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Le jeu n\'est pas initialisÃ©'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final gameName = gameState.gameName;
      if (gameName == null || gameName.isEmpty) {
        throw SaveError('NO_NAME', 'Aucun nom de partie dÃ©fini');
      }

      await gameState.saveGame(gameName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardÃ©e'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


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
  // DÃ©placer ces mÃ©thodes en dehors du bloc _showSettingsMenu et dans la classe _MainScreenState

// Ajoutez ces mÃ©thodes directement dans la classe _MainScreenState
  String _getLastSaveTimeText(GameState gameState) {
    final lastSave = gameState.lastSaveTime;
    if (lastSave == null) return 'Jamais';

    final now = DateTime.now();
    final difference = now.difference(lastSave);

    if (difference.inMinutes < 1) {
      return 'Ã€ l\'instant';
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
                child: Consumer<GameState>(
                  builder: (context, gameState, _) {
                    final stats = gameState.statistics.getAllStats();
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildStatSection('Production', stats['production']!),
                          const SizedBox(height: 16),
                          _buildStatSection('Ã‰conomie', stats['economie']!),
                          const SizedBox(height: 16),
                          _buildStatSection('Progression', stats['progression']!),
                        ],
                      ),
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
            const Text('Ã€ propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${GameConstants.VERSION}'),
            const SizedBox(height: 8),
            const Text('Un jeu incrÃ©mental de production de trombones.'),
            const SizedBox(height: 16),
            const Text('FonctionnalitÃ©s:'),
            const Text('â€¢ Production de trombones'),
            const Text('â€¢ Gestion du marchÃ©'),
            const Text('â€¢ SystÃ¨me d\'amÃ©liorations'),
            const Text('â€¢ Ã‰vÃ©nements dynamiques'),
            const SizedBox(height: 16),
            const Text('DÃ©veloppÃ© avec â¤ï¸ par Kinder2149'),
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
        print("Mode crise actif : ${gameState.isInCrisisMode}"); // Debug log

        final backgroundMusicService = context.watch<BackgroundMusicService>();

        // Construction de l'AppBar commun
        final appBar = AppBar(
          title: Text(
              gameState.isInCrisisMode
                  ? 'Nouveau Mode de Production'
                  : _getTitleForIndex(_selectedIndex),
              style: const TextStyle(color: Colors.white)
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple[700],
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildLevelIndicator(gameState.level),
          ),
          actions: [
            // Ajouter l'indicateur de mode compÃ©titif si on est en mode compÃ©titif
            if (gameState.gameMode == GameMode.COMPETITIVE)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: CompetitiveModeIndicator(),
              ),
            _buildNotificationButton(),
            IconButton(
              icon: Icon(
                backgroundMusicService.isPlaying ? Icons.volume_up : Icons
                    .volume_off,
                color: Colors.white,
              ),
              onPressed: _toggleMusic,
              tooltip: 'Activer/DÃ©sactiver la musique',
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => _showSettingsMenu(context),
              tooltip: 'ParamÃ¨tres',
            ),
          ],
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
                      : _getCurrentScreen(gameState.getVisibleScreenElements()),
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
                    gameState.getVisibleScreenElements()
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
        final visibleScreens = gameState.getVisibleScreenElements();
        final canProduce = gameState.player.metal >=
            GameConstants.METAL_PER_PAPERCLIP;

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
                                        '${GameConstants
                                            .METAL_PER_PAPERCLIP} mÃ©tal',
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
        return 'MarchÃ©';
      case 2:
        return 'AmÃ©liorations';
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
      valueListenable: EventManager().unreadCount,
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
      builder: (context) =>
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) =>
                Container(
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
                            // En-tÃªte
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: const [
                                  Icon(Icons.settings, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'ParamÃ¨tres',
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
                                    leading: const Icon(
                                        Icons.inventory_2_outlined),
                                    title: const Text('Trombones produits'),
                                    subtitle: Text(
                                        '${gameState.totalPaperclipsProduced}'),
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
                                    'Voir les statistiques dÃ©taillÃ©es'),
                                onTap: () => _showStatistics(context),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Section Google Play Games
                            FutureBuilder<bool>(
  future: GamesServicesController()))))).isSignedIn(),
  builder: (context, snapshot) {
    final isSignedIn = snapshot.data ?? false;

    return FutureBuilder<bool>(
      future: GamesServicesController()))))).isSignedIn(),
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;

        return Card(
          elevation: 0,
          color: Colors.grey[50],
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isSignedIn ? Icons.games : Icons.gamepad_outlined,
                  color: isSignedIn ? Colors.green : Colors.grey,
                ),
                title: Text(
                  isSignedIn
                      ? 'ConnectÃ© Ã  Google Play Games'
                      : 'Google Play Games',
                ),
                subtitle: Text(
                  isSignedIn
                      ? 'Vos parties peuvent Ãªtre synchronisÃ©es'
                      : 'Connectez-vous pour sauvegarder vos parties',
                ),
                trailing: isSignedIn
                    ? PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'switch') {
                      await GamesServicesController()))))).switchAccount();
                      setState(() {});
                    } else if (value == 'logout') {
                      // Comme signOut n'est pas disponible, on peut simplement rÃ©initialiser l'Ã©tat
                      await GamesServicesController()))))).signIn();
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'switch',
                      child: Text('Changer de compte'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('DÃ©connexion'),
                    ),
                  ],
                )
                    : TextButton(
                  onPressed: () async {
                    try {
                      await GamesServicesController())))))
                          .signIn();
                      setState(() {});
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                                'Erreur de connexion: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Se connecter'),
                ),
              ),

              // Garder le reste des sections comme avant
              if (isSignedIn) ...[
                                        const Divider(height: 1),
                                        ListTile(
                                          leading: const Icon(Icons.cloud_sync),
                                          title: const Text(
                                              'Synchroniser les sauvegardes'),
                                          subtitle: const Text(
                                              'Mettre Ã  jour vos sauvegardes dans le cloud'),
                                          onTap: () async {
                                            try {
                                              final success = await gameState
                                                  .syncSavesToCloud();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        success
                                                            ? 'Synchronisation rÃ©ussie'
                                                            : 'Ã‰chec de la synchronisation'
                                                    ),
                                                    backgroundColor: success
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text('Erreur: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const Divider(height: 1),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.cloud_download),
                                          title: const Text(
                                              'Charger depuis le cloud'),
                                          subtitle: const Text(
                                              'SÃ©lectionner une sauvegarde cloud'),
                                          onTap: () async {
                                            try {
                                              await gameState
                                                  .showCloudSaveSelector();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text('Erreur: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
            ],
          ),
        );
      },
    );
  },
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
                                      'DerniÃ¨re sauvegarde: ${_getLastSaveTimeText(
                                          gameState)}',
                                    ),
                                    onTap: () => _saveGame(context),
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
                            // Section Services de jeux
                            Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              child: Column(
                                children: [
                                  // En-tÃªte avec statut de connexion
                                  ListTile(
                                    leading: const Icon(Icons.games),
                                    title: const Text('Services de jeux'),
                                    trailing: FutureBuilder<bool>(
                                      future: GamesServicesController())))))
                                          .isSignedIn(),
                                      builder: (context, snapshot) {
                                        final isSignedIn = snapshot.data ??
                                            false;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isSignedIn
                                                  ? Icons.check_circle
                                                  : Icons.error_outline,
                                              color: isSignedIn
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            if (!isSignedIn)
                                              TextButton(
                                                onPressed: () =>
                                                    GamesServicesController())))))
                                                        .signIn(),
                                                child: const Text(
                                                    'Se connecter'),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(height: 1),

                                  // Classement gÃ©nÃ©ral
                                  ListTile(
                                    leading: const Icon(Icons.leaderboard),
                                    title: const Text('Classement GÃ©nÃ©ral'),
                                    subtitle: Text('Score global: ${gameState
                                        .totalPaperclipsProduced}'),
                                    onTap: () async {
                                      final controller = GamesServicesController())))));
                                      if (await controller.isSignedIn()) {
                                        gameState.updateLeaderboard();
                                        controller.showLeaderboard(leaderboardID: GamesServicesController.generalLeaderboardID);
                                      } else {
                                        await controller.signIn();
                                        if (await controller.isSignedIn()) {
                                          controller.showLeaderboard(leaderboardID: GamesServicesController.generalLeaderboardID);
                                        }
                                      }
                                    },
                                  ),
                                  const Divider(height: 1),

                                  // Classement production
                                  ListTile(
                                    leading: const Icon(
                                        Icons.precision_manufacturing),
                                    title: const Text('Meilleurs Producteurs'),
                                    subtitle: Text(
                                        'Production totale: ${gameState
                                            .totalPaperclipsProduced}'),
                                    onTap: () =>
                                        gameState.showProductionLeaderboard(),
                                  ),
                                  const Divider(height: 1),

                                  // Classement banquier
                                  ListTile(
                                    leading: const Icon(Icons.attach_money),
                                    title: const Text('Plus Grandes Fortunes'),
                                    subtitle: Text(
                                        'Fortune: ${gameState.statistics
                                            .getTotalMoneyEarned().toInt()}'),
                                    onTap: () =>
                                        gameState.showBankerLeaderboard(),
                                  ),
                                  const Divider(height: 1),

                                  // SuccÃ¨s
                                  ListTile(
                                    leading: const Icon(Icons.emoji_events),
                                    title: const Text('SuccÃ¨s'),
                                    subtitle: const Text(
                                        'Voir vos accomplissements'),
                                    onTap: () async {
                                      final controller = GamesServicesController())))));
                                      if (await controller.isSignedIn()) {
                                        controller.showAchievements();
                                      } else {
                                        await controller.signIn();
                                        if (await controller.isSignedIn()) {
                                          controller.showAchievements();
                                        }
                                      }
                                    },
                                  ),
                                  const Divider(height: 1),

                                  // Synchronisation
                                  ListTile(
                                    leading: const Icon(Icons.sync),
                                    title: const Text(
                                        'Synchroniser les scores'),
                                    subtitle: const Text(
                                        'Mettre Ã  jour tous les classements'),
                                    onTap: () async {
                                      final controller = GamesServicesController())))));
                                      if (await controller.isSignedIn()) {
                                        gameState.updateLeaderboard();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Scores synchronisÃ©s !'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Veuillez vous connecter aux services de jeux'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Section Ã€ propos
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
                                            'Un jeu de gestion incrÃ©mentale de production de trombones.'),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'DÃ©veloppÃ© avec â¤ï¸ par Kinder2149'),
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











// Ajoutez cette mÃ©thode pour la gestion de la sauvegarde
    Future<void> _handleSave(BuildContext context, GameState gameState) async {
      try {
        if (gameState.gameName == null) {
          throw SaveError('NO_NAME', 'Aucun nom de partie dÃ©fini');
        }
        await gameState.saveGame(gameState.gameName!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partie sauvegardÃ©e'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de sauvegarde: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }


  }
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
            'DÃ©bloquÃ© au niveau 7',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}






