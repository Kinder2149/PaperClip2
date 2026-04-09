// lib/widgets/new_game/new_game_dialog.dart
import 'package:flutter/material.dart';
import 'package:paperclip2/core/constants/constantes.dart';

Future<String?> showNewGameDialog({
  required BuildContext context,
  String? initialName,
}) async {
  final TextEditingController nameController =
      TextEditingController(text: initialName ?? PartieNaming.defaultName());
  String? nameError;
  StateSetter? _setNameState;
  return showDialog<String>(
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
            const Text(
              'Mode de jeu : Infini (progression libre)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              Navigator.of(ctx).pop(name);
            },
            child: const Text('Créer'),
          ),
        ],
      );
    },
  );
}
