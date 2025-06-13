// Script pour générer des fichiers spécifiques avec build_runner
import 'dart:io';

void main() async {
  // Liste des fichiers de modèles que nous voulons générer
  final modelFiles = [
    'lib/models/test_model.dart',
    'lib/models/user_model.dart',
    'lib/models/social/friend_model.dart',
    'lib/models/social/friend_request_model.dart',
    'lib/models/social/user_stats_model.dart',
  ];
  
  for (final modelFile in modelFiles) {
    print('Tentative de génération pour: $modelFile');
    
    try {
      // Exécuter build_runner juste pour ce fichier
      final result = await Process.run(
        'dart', 
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs', '--build-filter=$modelFile'], 
        runInShell: true
      );
      
      print('Sortie: ${result.stdout}');
      print('Erreur: ${result.stderr}');
      print('Code de sortie: ${result.exitCode}');
      print('-----------------------------------');
    } catch (e) {
      print('Exception: $e');
      print('-----------------------------------');
    }
  }
}
