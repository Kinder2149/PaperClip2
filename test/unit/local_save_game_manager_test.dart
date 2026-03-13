import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/constants/game_config.dart';

import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalSaveGameManager - basic local operations', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      // Force initialisation propre du singleton avant chaque test
      // en appelant getInstance() après avoir posé les valeurs mock.
      await LocalSaveGameManager.getInstance();
    });

    test('save -> list -> load -> delete', () async {
      final mgr = await LocalSaveGameManager.getInstance();

      final save = SaveGame(
        id: 'partie-1',
        name: 'Mon Monde',
        lastSaveTime: DateTime.now(),
        gameData: <String, dynamic>{
          'gameSnapshot': {
            'metadata': {
              'worldId': 'partie-1',
              'createdAt': DateTime.now().toIso8601String(),
            },
            'core': <String, dynamic>{},
            'market': <String, dynamic>{},
            'production': <String, dynamic>{},
            'stats': <String, dynamic>{},
          },
        },
        version: '2.0',
        gameMode: GameMode.INFINITE,
      );

      // save
      final okSave = await mgr.saveGame(save);
      expect(okSave, isTrue);

      // list
      final metas = await mgr.listSaves();
      expect(metas.any((m) => m.id == 'partie-1'), isTrue);

      // load
      final loaded = await mgr.loadSave('partie-1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Mon Monde');

      // delete
      final okDel = await mgr.deleteSave('partie-1');
      expect(okDel, isTrue);

      final after = await mgr.loadSave('partie-1');
      expect(after, isNull);
    });
  });
}
