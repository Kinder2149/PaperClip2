import 'package:flutter/material.dart';
import '../widgets/settings/settings_header.dart';
import '../widgets/settings/game_settings.dart';
import '../widgets/settings/account_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Sauvegarder les paramètres
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres sauvegardés')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SettingsHeader(),
            SizedBox(height: 24),
            GameSettings(),
            SizedBox(height: 24),
            AccountSettings(),
          ],
        ),
      ),
    );
  }
} 