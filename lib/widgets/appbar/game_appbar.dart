// lib/widgets/appbar/game_appbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../utils/responsive_utils.dart';
import 'level_badge.dart';
import 'appbar_actions.dart';
import 'resource_chip.dart';

class _GameAppBarView {
  final bool isInCrisisMode;
  final dynamic levelSystem;
  final String enterpriseName;
  final double money;
  final double paperclips;
  final int quantum;
  final int innovationPoints;

  const _GameAppBarView({
    required this.isInCrisisMode,
    required this.levelSystem,
    required this.enterpriseName,
    required this.money,
    required this.paperclips,
    required this.quantum,
    required this.innovationPoints,
  });

  @override
  bool operator ==(Object other) {
    return other is _GameAppBarView &&
        other.isInCrisisMode == isInCrisisMode &&
        other.levelSystem == levelSystem &&
        other.enterpriseName == enterpriseName &&
        other.money == money &&
        other.paperclips == paperclips &&
        other.quantum == quantum &&
        other.innovationPoints == innovationPoints;
  }

  @override
  int get hashCode => Object.hash(isInCrisisMode, levelSystem, enterpriseName, money, paperclips, quantum, innovationPoints);
}

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;
  final bool centerTitle;
  final VoidCallback? onSettingsPressed;
  
  const GameAppBar({
    Key? key,
    required this.selectedIndex,
    this.additionalActions,
    this.backgroundColor,
    this.centerTitle = true,
    this.onSettingsPressed,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(100); // Mobile: 100 (2 lignes) | Tablette/Desktop: 56 (1 ligne)

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _GameAppBarView>(
      selector: (context, gameState) => _GameAppBarView(
        isInCrisisMode: gameState.isInCrisisMode,
        levelSystem: gameState.level,
        enterpriseName: gameState.enterpriseName,
        money: gameState.playerManager.money,
        paperclips: gameState.playerManager.paperclips,
        quantum: gameState.rareResources.quantum,
        innovationPoints: gameState.rareResources.pointsInnovation,
      ),
      builder: (context, view, _) {
        final theme = Theme.of(context);
        final Color appBarColor = backgroundColor ??
            (theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : const Color(0xFF673AB7)); // Colors.deepPurple[700]

        // RESPONSIVE-APPBAR: toolbarHeight et layout dynamiques
        final toolbarHeight = const ResponsiveValue<double>(
          mobile: 100.0,
          tablet: 56.0,
          desktop: 56.0,
        ).getValue(context);

        final isMobile = context.isMobile;

        return AppBar(
          toolbarHeight: toolbarHeight,
          title: isMobile
              ? _buildMobileLayout(view)
              : _buildTabletDesktopLayout(view, context),
          centerTitle: true,
          backgroundColor: appBarColor,
          actions: AppBarActions(
            additionalActions: additionalActions,
            onSettingsPressed: onSettingsPressed,
          ).buildActions(context),
        );
      },
    );
  }

  /// Layout mobile (2 lignes) - COMPORTEMENT ACTUEL PRÉSERVÉ
  Widget _buildMobileLayout(_GameAppBarView view) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LIGNE 1: Niveau + Nom entreprise + Argent
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LevelBadge(levelSystem: view.levelSystem),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                view.enterpriseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ResourceChip(
              emoji: '💵',
              value: view.money,
              color: Colors.green.shade600,
              formatLarge: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // LIGNE 2: Trombones + Quantum + Points Innovation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ResourceChip(
              emoji: '📎',
              value: view.paperclips,
              color: Colors.blue.shade500,
              formatLarge: true,
            ),
            const SizedBox(width: 8),
            ResourceChip(
              emoji: '⚡',
              value: view.quantum.toDouble(),
              color: Colors.cyan.shade400,
              formatLarge: false,
            ),
            const SizedBox(width: 8),
            ResourceChip(
              emoji: '💡',
              value: view.innovationPoints.toDouble(),
              color: Colors.purple.shade400,
              formatLarge: false,
            ),
          ],
        ),
      ],
    );
  }

  /// Layout tablette/desktop (1 ligne) - NOUVEAU
  Widget _buildTabletDesktopLayout(_GameAppBarView view, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LevelBadge(levelSystem: view.levelSystem),
        const SizedBox(width: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            view.enterpriseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ResourceChip(
          emoji: '💵',
          value: view.money,
          color: Colors.green.shade600,
          formatLarge: true,
        ),
        const SizedBox(width: 12),
        ResourceChip(
          emoji: '📎',
          value: view.paperclips,
          color: Colors.blue.shade500,
          formatLarge: true,
        ),
        const SizedBox(width: 12),
        ResourceChip(
          emoji: '⚡',
          value: view.quantum.toDouble(),
          color: Colors.cyan.shade400,
          formatLarge: false,
        ),
        const SizedBox(width: 12),
        ResourceChip(
          emoji: '💡',
          value: view.innovationPoints.toDouble(),
          color: Colors.purple.shade400,
          formatLarge: false,
        ),
      ],
    );
  }
}
