// lib/presentation/screens/save_load_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/router.dart';
import '../../core/constants/imports.dart';
import '../../core/constants/game_constants.dart';
import '../viewmodels/game_viewmodel.dart';
import '../../domain/entities/save_game_info.dart';
import '../../domain/services/games_services_controller.dart';
import '../widgets/save_load/save_load_header.dart';
import '../widgets/save_load/save_list.dart';
import '../widgets/save_load/new_save.dart';

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde et Chargement'),
      ),
      body: Consumer<GameViewModel>(
        builder: (context, gameViewModel, child) {
          if (gameViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gameViewModel.error!,
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: gameViewModel.retry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SaveLoadHeader(),
                SizedBox(height: 16),
                NewSave(),
                SizedBox(height: 16),
                SaveList(),
              ],
            ),
          );
        },
      ),
    );
  }
}