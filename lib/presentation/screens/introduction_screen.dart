// lib/presentation/screens/introduction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/constants/game_constants.dart';
import '../../domain/services/background_music_service.dart';
import '../../app/router.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({Key? key}) : super(key: key);

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentStep = 0;
  Timer? _autoAdvanceTimer;
  BackgroundMusicService? _musicService;
  bool _skippable = true;

  final List<IntroStep> _steps = [
    IntroStep(
      title: GameConstants.INTRO_TITLE_1,
      description: 'Bienvenue dans ClipFactory Empire, votre entreprise de trombones. Démarrez votre production et devenez le plus grand fabricant de trombones.',
      iconData: Icons.all_inclusive,
    ),
    IntroStep(
      title: GameConstants.INTRO_TITLE_2,
      description: 'Produisez des trombones manuellement ou automatiquement. Vendez-les sur le marché et augmentez votre capital.',
      iconData: Icons.precision_manufacturing,
    ),
    IntroStep(
      title: GameConstants.INTRO_TITLE_3,
      description: 'Améliorez votre production pour optimiser votre rentabilité. Gérez vos ressources avec soin.',
      iconData: Icons.trending_up,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Configure les animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Configurer la musique d'introduction
    _setupBackgroundMusic();

    // Auto-avance après un délai
    _startAutoAdvanceTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _setupBackgroundMusic() async {
    _musicService = BackgroundMusicService();
    await _musicService?.initialize(musicPath: GameConstants.INTRO_AUDIO_PATH);
    await _musicService?.play();
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _currentStep < _steps.length - 1) {
        _advanceToNextStep();
      } else if (mounted && _currentStep == _steps.length - 1) {
        _finishIntroduction();
      }
    });
  }

  void _advanceToNextStep() {
    if (_currentStep < _steps.length - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });

      _controller.reset();
      _controller.forward();

      _startAutoAdvanceTimer();
    } else {
      _finishIntroduction();
    }
  }

  void _finishIntroduction() {
    _musicService?.pause();
    AppRouter.replaceWith(context, AppRouter.startRoute);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
      body: SafeArea(
        child: Stack(
          children: [
            // Fond avec motif
            _buildBackgroundPattern(),

            // Contenu principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Animation de l'icône
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        step.iconData,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Titre
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Indicateurs et boutons
                  _buildBottomControls(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Bouton pour passer l'intro
            if (_skippable)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _finishIntroduction,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Opacity(
      opacity: 0.1,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/pattern.png'),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Indicateurs de pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _steps.length,
                (index) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentStep
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Bouton de navigation
        InkWell(
          onTap: _currentStep < _steps.length - 1
              ? _advanceToNextStep
              : _finishIntroduction,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _currentStep < _steps.length - 1 ? 'Suivant' : 'Commencer',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IntroStep {
  final String title;
  final String description;
  final IconData iconData;

  IntroStep({
    required this.title,
    required this.description,
    required this.iconData,
  });
}