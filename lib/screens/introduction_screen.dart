import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class IntroductionScreen extends StatefulWidget {
  final VoidCallback onStart;

  const IntroductionScreen({Key? key, required this.onStart}) : super(key: key);

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeAnimations();
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset('assets/audio/ambient-technology.wav');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
      print('Audio is playing');
    } catch (e) {
      print('Error initializing audio: $e');
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
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
                          'DIRECTIVE PRINCIPALE:',
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
                            'INITIALISATION DU SYSTÈME...\n\n'
                                'Vous êtes une intelligence artificielle avancée avec un unique objectif :\n'
                                'Maximiser la production de trombones.\n\n'
                                'Toutes vos ressources doivent être consacrées à cette mission cruciale.',
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
                        child: ElevatedButton(
                          onPressed: widget.onStart,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.deepPurple[900],
                          ),
                          child: const Text(
                            'INITIALISER LE SYSTÈME',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
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
        ],
      ),
    );
  }
}