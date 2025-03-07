import 'package:flutter/material.dart';
import '../models/game_config.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Widget? customContent;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.customContent,
  });
}

class TutorialDialog extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final bool showSkip;

  const TutorialDialog({
    Key? key,
    required this.steps,
    this.onComplete,
    this.showSkip = true,
  }) : super(key: key);

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();

  static void showProductionTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialDialog(
        steps: [
          TutorialStep(
            title: 'Production Manuelle',
            description: 'Cliquez sur le bouton pour produire un trombone.\n'
                'Chaque trombone consomme ${GameConstants.METAL_PER_PAPERCLIP} unité de métal.',
            icon: Icons.touch_app,
          ),
          TutorialStep(
            title: 'Ressources',
            description: 'Surveillez vos ressources :\n'
                '• Métal : nécessaire pour la production\n'
                '• Argent : pour acheter des améliorations\n'
                '• Trombones : à vendre sur le marché',
            icon: Icons.inventory_2,
          ),
          TutorialStep(
            title: 'Combos',
            description: 'Produisez rapidement pour obtenir des combos !\n'
                'Les combos augmentent l\'expérience gagnée.',
            icon: Icons.flash_on,
          ),
        ],
        onComplete: () {
          // Marquer le tutoriel comme complété
        },
      ),
    );
  }

  static void showMarketTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialDialog(
        steps: [
          TutorialStep(
            title: 'Le Marché',
            description: 'Vendez vos trombones sur le marché.\n'
                'Le prix de vente influence la demande.',
            icon: Icons.storefront,
          ),
          TutorialStep(
            title: 'Demande',
            description: 'Une demande élevée = ventes plus rapides\n'
                'Une demande faible = ventes plus lentes',
            icon: Icons.trending_up,
          ),
          TutorialStep(
            title: 'Réputation',
            description: 'Votre réputation influence les prix maximum.\n'
                'Maintenez des prix raisonnables pour l\'améliorer.',
            icon: Icons.star,
          ),
        ],
      ),
    );
  }

  static void showUpgradesTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialDialog(
        steps: [
          TutorialStep(
            title: 'Améliorations',
            description: 'Améliorez votre production avec :\n'
                '• Efficacité : meilleure utilisation du métal\n'
                '• Stockage : plus grande capacité\n'
                '• Marketing : meilleures ventes',
            icon: Icons.upgrade,
          ),
          TutorialStep(
            title: 'Automation',
            description: 'Les autoclippers produisent automatiquement.\n'
                'Ils consomment du métal en continu.',
            icon: Icons.precision_manufacturing,
          ),
          TutorialStep(
            title: 'Maintenance',
            description: 'Entretenez vos machines pour maintenir l\'efficacité.\n'
                'La maintenance a un coût mais est essentielle.',
            icon: Icons.build,
          ),
        ],
      ),
    );
  }
}

class _TutorialDialogState extends State<TutorialDialog> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isLastPage = widget.steps.length == 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
      widget.onComplete?.call();
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == widget.steps.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tutoriel ${_currentPage + 1}/${widget.steps.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.showSkip)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onComplete?.call();
                      },
                      child: const Text('Passer'),
                    ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  final step = widget.steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          step.icon,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (step.customContent != null) ...[
                          const SizedBox(height: 24),
                          step.customContent!,
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicateurs de page
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.steps.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),

            // Bouton
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(_isLastPage ? 'Terminer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 