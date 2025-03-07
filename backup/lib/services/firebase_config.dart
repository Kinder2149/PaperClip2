import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      // Configuration Remote Config
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Valeurs par défaut pour votre jeu
      await remoteConfig.setDefaults(const {
        'metal_per_paperclip': 0.15,
        'initial_price': 0.25,
        'efficiency_multiplier': 0.10,
        'max_efficiency_level': 8,
      });

      // Premier fetch avec gestion d'erreur
      await remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      print('Error initializing Firebase Config: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  static Future<void> saveGameToCloud(String userId, String saveData) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      await ref.putString(
        saveData,
        metadata: SettableMetadata(
          contentType: 'application/json',
          customMetadata: {'lastSaved': DateTime.now().toIso8601String()},
        ),
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  static Future<String?> loadGameFromCloud(String userId) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      final data = await ref.getData();
      return data != null ? String.fromCharCodes(data) : null;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  static Future<bool> checkSaveExists(String userId) async {
    try {
      final ref = storage.ref('saves/$userId/game_save.json');
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}