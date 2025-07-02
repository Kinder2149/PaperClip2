// lib/widgets/appbar/sections/music_control_action.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/background_music.dart';

class MusicControlAction extends StatelessWidget {
  const MusicControlAction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundMusicService>(
      builder: (context, backgroundMusicService, _) {
        return IconButton(
          icon: Icon(
            backgroundMusicService.isPlaying ? Icons.volume_up : Icons.volume_off,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
          ),
          onPressed: () => _toggleMusic(backgroundMusicService),
          tooltip: 'Activer/Désactiver la musique',
        );
      },
    );
  }

  Future<void> _toggleMusic(BackgroundMusicService backgroundMusicService) async {
    if (backgroundMusicService.isPlaying) {
      await backgroundMusicService.pause();
    } else {
      await backgroundMusicService.play();
    }
  }
}
