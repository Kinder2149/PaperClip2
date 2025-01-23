import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/game_config.dart';
import 'main_screen.dart';

class IntroductionScreen extends StatefulWidget {
  final VoidCallback onStart;
  final bool showSkipButton;
  static const DateTime CURRENT_DATE = DateTime(2025, 1, 23, 15, 31, 18);
  static const String CURRENT_USER = 'Kinder2149';

  const IntroductionScreen({
    Key? key,
    required this.onStart,
    this.showSkipButton = false,
  }) : super(key: key);

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;
  int _currentPage = 0;

  // Mise à jour du contenu avec des constantes
  final List<Map<String, String>> _introPages = [
    {
      'title': GameConstants.INTRO_TITLE_1,
      'content': """INITIALISATION DU SYSTÈME...

Vous êtes une intelligence artificielle avancée avec un unique objectif :
Maximiser la production de trombones.

Toutes vos ressources doivent être consacrées à cette mission cruciale.""",
    },
    {
      'title': GameConstants.INTRO_TITLE_2,
      'content': """MÉCANISMES DE PRODUCTION

• Production manuelle et automatisée
• Gestion des ressources et du métal
• Système de niveau et progression
• Marché dynamique et économie""",
    },
    {
      'title': GameConstants.INTRO_TITLE_3,
      'content': """OPTIMISATION DES OPÉRATIONS

• Développez votre production
• Gérez vos ressources efficacement
• Surveillez les conditions du marché
• Améliorez vos capacités de production""",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeAnimations();
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset(GameConstants.INTRO_AUDIO_PATH);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error initializing audio: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
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
                return Column(
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
                          _introPages[_currentPage]['title']!,
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
                    FadeTransition(
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
                            _introPages[_currentPage]['content']!,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentPage > 0)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                },
                                child: const Text(
                                  'PRÉCÉDENT',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: _currentPage < _introPages.length - 1
                                  ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                                  : widget.onStart,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: Colors.deepPurple[900],
                              ),
                              child: Text(
                                _currentPage < _introPages.length - 1
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
                  ],
                );
              },
            ),
          ),
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
                onPressed: widget.onStart,
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
    super.dispose();
  }
}