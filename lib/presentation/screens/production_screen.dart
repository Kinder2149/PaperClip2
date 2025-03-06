// lib/presentation/screens/production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/constants/imports.dart';
import '../../core/constants/game_constants.dart';
import '../viewmodels/production_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/production_button.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/production/production_header.dart';
import '../widgets/production/production_controls.dart';
import '../widgets/production/production_stats.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({Key? key}) : super(key: key);

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  Timer? _productionTimer;
  int _comboCount = 0;
  int _productionPerSecond = 0;
  bool _showingUpgradeTooltip = false;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Simulation de production d'autoclippers
    _startProductionTimer();
    _loadPlayerState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _productionTimer?.cancel();
    super.dispose();
  }

  void _startProductionTimer() {
    _productionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateProductionRate(),
    );
  }

  void _updateProductionRate() {
    final productionViewModel = Provider.of<ProductionViewModel>(context, listen: false);
    final player = productionViewModel.playerState;

    if (player != null) {
      setState(() {
        _productionPerSecond = player.autoclippers;
      });
    }
  }

  void _producePaperclip() {
    final productionViewModel = Provider.of<ProductionViewModel>(context, listen: false);
    productionViewModel.producePaperclip();

    // Animation pulsation
    _controller.reset();
    _controller.forward();

    // Gestion du combo
    _increaseCombo();
  }

  void _increaseCombo() {
    setState(() {
      _comboCount++;

      // Réinitialiser le combo après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _comboCount = 0;
          });
        }
      });
    });
  }

  Future<void> _buyAutoclipper() async {
    final productionViewModel = Provider.of<ProductionViewModel>(context, listen: false);
    final success = await productionViewModel.buyAutoclipper();

    if (success) {
      _updateProductionRate();

      // Afficher un snackbar de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autoclipper acheté! Vous avez maintenant ${productionViewModel.playerState?.autoclippers} autoclippers.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Afficher une erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'acheter un autoclipper. Fonds insuffisants.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpgradeTooltip() {
    setState(() {
      _showingUpgradeTooltip = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingUpgradeTooltip = false;
        });
      }
    });
  }

  Future<void> _loadPlayerState() async {
    final productionViewModel = Provider.of<ProductionViewModel>(context, listen: false);
    await productionViewModel.loadPlayerState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
      ),
      body: Consumer<ProductionViewModel>(
        builder: (context, productionViewModel, child) {
          if (productionViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productionViewModel.error != null) {
            return Center(
              child: Text(
                'Erreur: ${productionViewModel.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProductionHeader(),
                const SizedBox(height: 16),
                const ProductionControls(),
                const SizedBox(height: 16),
                const ProductionStats(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourcesSection(PlayerEntity player, double metalPerClip) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Trombones
                Expanded(
                  child: ResourceDisplay(
                    label: 'Trombones',
                    value: player.paperclips,
                    icon: Icons.attachment,
                    color: Colors.blue,
                  ),
                ),

                // Métal
                Expanded(
                  child: ResourceDisplay(
                    label: 'Métal',
                    value: player.metal,
                    icon: Icons.inventory_2,
                    color: Colors.blueGrey,
                  ),
                ),

                // Argent
                Expanded(
                  child: ResourceDisplay(
                    label: 'Argent',
                    value: player.money,
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Capacité de stockage
            ProgressBar(
              progress: player.metal / player.maxMetalStorage,
              label: 'Stockage: ${player.metal.toStringAsFixed(1)} / ${player.maxMetalStorage.toStringAsFixed(0)}',
              color: Colors.blue,
            ),

            // Indicateur de métal restant
            const SizedBox(height: 4),
            Text(
              'Métal pour ${(player.metal / metalPerClip).toStringAsFixed(0)} trombones',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}