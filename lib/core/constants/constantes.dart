// Point central de constantes et enums de l'application
// Réexporte les constantes existantes et expose les types nécessaires.

import 'package:paperclip2/constants/game_config.dart';

export 'package:paperclip2/constants/game_config.dart'
    show GameConstants, GameMode, UnlockableFeature, ProgressionPath;

/// Version contractuelle du format de GameSnapshot (obligatoire dans metadata.version)
const int GAME_SNAPSHOT_CONTRACT_VERSION = 1;

/// Fonctions utilitaires pour les noms de partie
class PartieNaming {
  static String defaultName() {
    final now = DateTime.now();
    return '${GameConstants.DEFAULT_GAME_NAME_PREFIX} ${now.day}/${now.month}';
  }
}
