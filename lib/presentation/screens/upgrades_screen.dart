// lib/presentation/screens/upgrades_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/upgrades_viewmodel.dart';
import '../widgets/upgrades/upgrades_header.dart';
import '../widgets/upgrades/upgrade_categories.dart';
import '../widgets/upgrades/upgrade_list.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Améliorations'),
      ),
      body: Consumer<UpgradesViewModel>(
        builder: (context, upgradesViewModel, child) {
          if (upgradesViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (upgradesViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    upgradesViewModel.error!,
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: upgradesViewModel.retry,
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
                UpgradesHeader(),
                SizedBox(height: 16),
                UpgradeCategories(),
                SizedBox(height: 16),
                UpgradeList(),
              ],
            ),
          );
        },
      ),
    );
  }
}