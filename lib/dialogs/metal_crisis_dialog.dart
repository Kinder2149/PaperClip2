// lib/dialogs/metal_crisis_dialog.dart
// Modifier le dialogue de crise pour tenir compte du mode compétitif

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../screens/competitive_result_screen.dart';
import '../widgets/buttons/action_button.dart';

class MetalCrisisDialog extends StatefulWidget {
  final VoidCallback? onTransitionComplete;

  const MetalCrisisDialog({
    Key? key,
    this.onTransitionComplete,
  }) : super(key: key);

  @override
  State<MetalCrisisDialog> createState() => _MetalCrisisDialogState();
}

class _MetalCrisisDialogState extends State<MetalCrisisDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    // Afficher les boutons immédiatement pour éviter les problèmes
    _showButtons = true;
    
    // S'assurer que les boutons sont visibles après un court délai au cas où
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, bool>(
      selector: (context, gameState) => gameState.gameMode == GameMode.COMPETITIVE,
      builder: (context, isCompetitiveMode, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade800,
                          Colors.deepOrange.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre
                        Text(
                          isCompetitiveMode
                              ? 'FIN DE PARTIE COMPÉTITIVE'
                              : 'ALERTE MONDIALE',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Icône d'alerte
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompetitiveMode ? Icons.emoji_events : Icons.warning,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isCompetitiveMode
                                ? 'Les ressources mondiales de métal sont épuisées. Votre partie compétitive est terminée.\n\nVotre score a été calculé et enregistré!'
                                : 'ALERTE : Les ressources mondiales de métal sont épuisées.\n\nVotre système va entrer dans une nouvelle phase d\'adaptation.',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Boutons (apparaissent après l'animation)
                        AnimatedOpacity(
                          opacity: _showButtons ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: isCompetitiveMode
                                ? [
                                    // Bouton pour voir les résultats en mode compétitif
                                    ActionButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Calculer le score et afficher l'écran de résultats
                                        context
                                            .read<GameState>()
                                            .handleCompetitiveGameEnd();
                                      },
                                      label: 'VOIR MES RÉSULTATS',
                                      icon: Icons.assessment,
                                      backgroundColor: Colors.amber,
                                      textColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 15,
                                      ),
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]
                                : [
                                    // Bouton pour continuer en mode infini
                                    ActionButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Appeler le callback de transition si fourni
                                        widget.onTransitionComplete?.call();
                                      },
                                      label: 'CONTINUER',
                                      icon: Icons.arrow_forward,
                                      backgroundColor: Colors.white,
                                      textColor: Colors.deepOrange.shade900,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 15,
                                      ),
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}