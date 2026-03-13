// lib/widgets/new_game/new_game_dialog.dart
import 'package:flutter/material.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/core/constants/constantes.dart';

Future<(String, GameMode)?> showNewGameDialog({
  required BuildContext context,
  String? initialName,
  GameMode initialMode = GameMode.INFINITE,
}) async {
  final TextEditingController nameController =
      TextEditingController(text: initialName ?? PartieNaming.defaultName());
  GameMode selectedMode = initialMode;
  String? nameError;
  StateSetter? _setNameState;
  return showDialog<(String, GameMode)>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Nouveau monde'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                _setNameState = setState;
                return TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du monde',
                    helperText: 'Au moins 3 caractères',
                    errorText: nameError,
                  ),
                  onChanged: (val) {
                    final ok = val.trim().length >= 3;
                    if (nameError != null && ok) {
                      setState(() => nameError = null);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<GameMode>(
                      title: const Text('Infini'),
                      subtitle: const Text('Progression libre, sans limite de temps.'),
                      value: GameMode.INFINITE,
                      groupValue: selectedMode,
                      onChanged: (val) {
                        if (val != null) setState(() => selectedMode = val);
                      },
                    ),
                    RadioListTile<GameMode>(
                      title: const Text('Compétitif'),
                      subtitle: const Text('Session à score, pensée pour la comparaison.'),
                      value: GameMode.COMPETITIVE,
                      groupValue: selectedMode,
                      onChanged: (val) {
                        if (val != null) setState(() => selectedMode = val);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = nameController.text.trim();
              if (trimmed.length < 3) {
                _setNameState?.call(() {
                  nameError = 'Nom trop court (min. 3 caractères)';
                });
                return;
              }
              final name = trimmed;
              Navigator.of(ctx).pop((name, selectedMode));
            },
            child: const Text('Créer'),
          ),
        ],
      );
    },
  );
}
