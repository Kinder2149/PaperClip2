// integration_test/cloud_save_e2e_test.dart
// Squelette d'E2E pour le flux cloud par partie.
// Pré-requis:
// - FEATURE_CLOUD_PER_PARTIE=true dans .env
// - Un backend mocké via intercepteur HTTP (ou serveur de test)
// - Fake identité Google (playerId non vide)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

// App imports
import 'package:paperclip2/services/saves/saves_facade.dart';
import 'package:paperclip2/widgets/cloud/cloud_sync_status_button.dart';
// TODO: importer StartScreen, SaveLoadScreen, RuntimeActions si on veut piloter l'app complète
// import 'package:paperclip2/screens/start_screen.dart';

// Fakes minimalistes (intercepteur HTTP + identité)
class FakeGoogleIdentityService {
  final String? playerId;
  FakeGoogleIdentityService(this.playerId);
  Future<void> refresh() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E cloud by partie (squelette)', () {
    testWidgets('sign-in → new game → SaveLoad → bouton cloud → push → refresh', (tester) async {
      // NOTE: Ce test est un squelette et est marqué skipped par défaut.
    }, skip: true);
  });
}
