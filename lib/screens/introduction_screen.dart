// lib/screens/introduction_screen.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'main_screen.dart';
import 'package:flutter/animation.dart';

class IntroductionScreen extends StatefulWidget {
  final bool showSkipButton;
  final VoidCallback onStart;
  final bool isCompetitiveMode;

  const IntroductionScreen({
    Key? key,
    this.showSkipButton = false,
    required this.onStart,
    this.isCompetitiveMode = false,
  }) : super(key: key);

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}


class _IntroductionScreenState extends State<IntroductionScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();


  void _handleNavigation() {
    if (!mounted) return;

    // Vérifier que le callback existe avant de l'appeler
    widget.onStart();
  }

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeAnimations();
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset('assets/audio/intro.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Audio non disponible: $e');
      // Continuer sans audio
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideUp = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Widget _buildIntroPage({
    required String title,
    required String description,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple[900]!,
            Colors.deepPurple[700]!,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: const Icon(
                        Icons.memory,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentPage > 0) ...[
                              TextButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: const Text(
                                  'PRÉCÉDENT',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 20),
                            ],
                            ElevatedButton(
                              onPressed: _currentPage < 2
                                  ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              }
                                  : _handleNavigation,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: Colors.deepPurple[900],
                              ),
                              child: Text(
                                _currentPage < 2
                                    ? 'SUIVANT'
                                    : 'INITIALISER LE SYSTÈME',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              // Première page standard
              _buildIntroPage(
                title: GameConstants.INTRO_TITLE_1,
                description: widget.isCompetitiveMode
                    ? "Bienvenue dans le mode compétitif de Paperclip !\n\nDans ce mode, votre objectif est d'optimiser votre production et d'obtenir le meilleur score possible avant l'épuisement mondial du métal."
                    : "Bienvenue dans Paperclip, un jeu incrémental où vous allez créer un empire de trombones. Commencez petit et automatisez votre production pour grandir.",
                image: "assets/intro1.png",
              ),

              // Deuxième page standard avec information compétitive
              _buildIntroPage(
                title: GameConstants.INTRO_TITLE_2,
                description: widget.isCompetitiveMode
                    ? "Produisez efficacement pour maximiser votre score. Les trombones, l'argent et le niveau atteint contribuent tous à votre score final. Plus vous êtes rapide et efficace, plus votre score sera élevé !"
                    : "Cliquez pour produire des trombones manuellement. Achetez du métal et améliorez votre production pour augmenter l'efficacité.",
                image: "assets/intro2.png",
              ),

              // Troisième page adaptée au mode
              _buildIntroPage(
                title: widget.isCompetitiveMode ? "COMPÉTITION" : GameConstants.INTRO_TITLE_3,
                description: widget.isCompetitiveMode
                    ? "Le métal est une ressource limitée ! Lorsque le stock mondial sera épuisé, votre partie compétitive se terminera et votre score sera enregistré. Comparez vos résultats avec vos amis et visez le haut du classement !"
                    : "Gérez vos ressources et prenez des décisions stratégiques. Déverrouillez de nouvelles fonctionnalités en progressant dans les niveaux.",
                image: "assets/intro3.png",
              ),
            ],
          ),

          // Boutons en overlay
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                  if (_isMuted) {
                    _audioPlayer.setVolume(0);
                  } else {
                    _audioPlayer.setVolume(1);
                  }
                });
              },
            ),
          ),
          if (widget.showSkipButton)
            Positioned(
              top: 40,
              left: 20,
              child: TextButton(
                onPressed: _handleNavigation,
                child: const Text(
                  'PASSER',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }
}