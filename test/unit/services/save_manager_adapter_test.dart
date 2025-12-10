// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:paperclip2/constants/game_config.dart';
// Import SaveGame uniquement depuis services/save_game.dart pour éviter le conflit
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';

// Génération des mocks pour LocalSaveGameManager
@GenerateMocks([LocalSaveGameManager])
import 'save_manager_adapter_test.mocks.dart';

void main() {
  group('SaveManagerAdapter Tests', () {
    late MockLocalSaveGameManager mockManager;
    
    setUp(() {
      mockManager = MockLocalSaveGameManager();
      // Remplacer l'instance de LocalSaveGameManager dans SaveManagerAdapter
      SaveManagerAdapter.instance = mockManager;
    });
    
    tearDown(() {
      // Nettoyage après les tests
      // Note: Dans une application réelle, il faudrait réinitialiser l'instance
      // mais ici pour les tests, ce n'est pas critique
    });
    
    test('listSaves convertit correctement SaveMetadata en SaveGameInfo', () async {
      // Créer des métadonnées de test
      final date1 = DateTime(2023, 1, 15);
      final metadata1 = SaveMetadata(
        id: 'save1',
        name: 'Save 1',
        creationDate: date1,  // Ajout du champ requis
        lastModified: date1,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      final date2 = DateTime(2023, 2, 20);
      final metadata2 = SaveMetadata(
        id: 'save2',
        name: 'Save 2',
        creationDate: date2,  // Ajout du champ requis
        lastModified: date2,
        version: '1.0.0',
        gameMode: GameMode.COMPETITIVE,
        isRestored: true,
      );
      
      // Configurer le mock pour retourner nos métadonnées de test
      when(mockManager.listSaves()).thenAnswer((_) => Future.value([metadata1, metadata2]));
      
      // Configurer le mock pour la première sauvegarde
      final saveGame1 = SaveGame(
        id: metadata1.id,
        name: metadata1.name,
        gameMode: metadata1.gameMode,
        lastSaveTime: metadata1.lastModified,
        version: metadata1.version,
        gameData: {
          'playerManager': {
            'paperclips': 1000,
            'money': 500,
            'totalPaperclipsSold': 2000,
            'autoClipperCount': 5,
          }
        },
      );
      when(mockManager.loadSave('save1')).thenAnswer((_) => Future.value(saveGame1));
      
      // Configurer le mock pour la deuxième sauvegarde
      final saveGame2 = SaveGame(
        id: metadata2.id,
        name: metadata2.name,
        gameMode: metadata2.gameMode,
        lastSaveTime: metadata2.lastModified,
        version: metadata2.version,
        gameData: {
          'playerManager': {
            'paperclips': 2000,
            'money': 1000,
            'totalPaperclipsSold': 5000,
            'autoClipperCount': 10,
          }
        },
      );
      when(mockManager.loadSave('save2')).thenAnswer((_) => Future.value(saveGame2));
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier les résultats
      expect(saves.length, 2);
      
      // Vérifier la première sauvegarde
      expect(saves[0].id, 'save1');
      expect(saves[0].name, 'Save 1');
      expect(saves[0].lastModified, DateTime(2023, 1, 15));
      expect(saves[0].gameMode, GameMode.INFINITE);
      expect(saves[0].isRestored, false);
      expect(saves[0].isBackup, false);
      expect(saves[0].paperclips, 1000);
      expect(saves[0].money, 500);
      expect(saves[0].totalPaperclipsSold, 2000);
      expect(saves[0].autoClipperCount, 5);
      
      // Vérifier la deuxième sauvegarde
      expect(saves[1].id, 'save2');
      expect(saves[1].name, 'Save 2');
      expect(saves[1].lastModified, DateTime(2023, 2, 20));
      expect(saves[1].gameMode, GameMode.COMPETITIVE);
      expect(saves[1].isRestored, true);
      expect(saves[1].isBackup, false);
      expect(saves[1].paperclips, 2000);
      expect(saves[1].money, 1000);
      expect(saves[1].totalPaperclipsSold, 5000);
      expect(saves[1].autoClipperCount, 10);
    });
    
    test('listSaves gère correctement les erreurs de chargement', () async {
      // Créer une métadonnée de test
      final errorDate = DateTime(2023, 3, 10);
      final metadata = SaveMetadata(
        id: 'error-save',
        name: 'Save with Error',
        creationDate: errorDate,  // Ajout du champ requis
        lastModified: errorDate,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      // Configurer le mock pour retourner notre métadonnée
      when(mockManager.listSaves()).thenAnswer((_) => Future.value([metadata]));
      
      // Simuler une erreur lors du chargement de la sauvegarde
      when(mockManager.loadSave('error-save')).thenThrow(Exception('Test error'));
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier que la sauvegarde est retournée avec des valeurs par défaut
      expect(saves.length, 1);
      expect(saves[0].id, 'error-save');
      expect(saves[0].name, 'Save with Error');
      expect(saves[0].lastModified, DateTime(2023, 3, 10));
      expect(saves[0].paperclips, 0); // Valeur par défaut
      expect(saves[0].money, 0); // Valeur par défaut
    });
    
    test('listSaves gère les sauvegardes de type backup', () async {
      // Créer une métadonnée de sauvegarde backup
      final backupName = 'Regular Save${GameConstants.BACKUP_DELIMITER}20230401';
      final backupDate = DateTime(2023, 4, 1);
      final backupMetadata = SaveMetadata(
        id: 'backup1',
        name: backupName,
        creationDate: backupDate,  // Ajout du champ requis
        lastModified: backupDate,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      // Configurer le mock
      when(mockManager.listSaves()).thenAnswer((_) => Future.value([backupMetadata]));
      
      // Ne pas configurer loadSave car les backups ne chargent pas les données du jeu
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier les résultats
      expect(saves.length, 1);
      expect(saves[0].name, backupName);
      expect(saves[0].isBackup, true);
      expect(saves[0].paperclips, 0); // Les backups n'ont pas de données de jeu
      expect(saves[0].money, 0);
    });
  });
}
