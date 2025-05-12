// lib/services/save/storage/cloud_storage_engine.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:games_services/games_services.dart' as gs;
import '../../../models/game_config.dart';
import 'package:http/http.dart' as http;

import '../save_types.dart';
import '../../user/google_auth_service.dart';
import 'storage_engine.dart';

class CloudStorageEngine implements StorageEngine {
  static const String CLOUD_SAVE_PREFIX = 'paperclip2_save_';
  static const String APP_FOLDER_NAME = 'ClipFactoryEmpire';

  final GoogleAuthService _authService = GoogleAuthService();
  bool _initialized = false;
  drive.DriveApi? _driveApi;
  String? _appFolderId;

  @override
  Future<bool> initialize() async {
    try {
      // Tenter d'initialiser Google Drive
      if (await _initializeDrive()) {
        _initialized = true;
        return true;
      }

      // En cas d'échec, vérifier si Google Play Games est disponible
      if (await _isPlayGamesAvailable()) {
        _initialized = true;
        return true;
      }

      _initialized = false;
      return false;
    } catch (e, stack) {
      debugPrint('Erreur initialisation cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      _initialized = false;
      return false;
    }
  }

  @override
  bool get isInitialized => _initialized;

  // Implémentation Google Drive avec gestion d'erreurs améliorée
  Future<bool> _initializeDrive() async {
    try {
      final accessToken = await _authService.getGoogleAccessToken();
      if (accessToken == null) return false;

      final client = http.Client();
      final headers = {'Authorization': 'Bearer $accessToken'};
      final authClient = _AuthClient(client, headers);

      _driveApi = drive.DriveApi(authClient);

      // Rechercher ou créer le dossier d'application avec gestion d'erreur robuste
      try {
        final fileList = await _driveApi!.files.list(
          q: "name='$APP_FOLDER_NAME' and mimeType='application/vnd.google-apps.folder' and trashed=false",
          $fields: 'files(id, name)',
        );

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          _appFolderId = fileList.files!.first.id;
          return true;
        }

        // Créer le dossier s'il n'existe pas
        final folderMetadata = drive.File()
          ..name = APP_FOLDER_NAME
          ..mimeType = 'application/vnd.google-apps.folder';

        final folder = await _driveApi!.files.create(folderMetadata);
        _appFolderId = folder.id;

        return true;
      } catch (driveError) {
        debugPrint('Erreur lors de la recherche/création du dossier Drive: $driveError');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur initialisation Drive: $e');
      return false;
    }
  }
  @override
  Future<void> save(SaveGame saveGame) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_driveApi != null && _appFolderId != null) {
        await _saveToDrive(saveGame);
      } else if (await _isPlayGamesAvailable()) {
        await _saveToPlayGames(saveGame);
      } else {
        throw SaveError('CLOUD_UNAVAILABLE', 'Service de cloud non disponible');
      }

      // Mettre à jour l'état de la sauvegarde
      saveGame.isSyncedWithCloud = true;
      if (saveGame.cloudId == null) {
        saveGame.cloudId = saveGame.id;
      }
    } catch (e, stack) {
      debugPrint('Erreur sauvegarde cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<void> _saveToDrive(SaveGame saveGame) async {
    final saveJson = jsonEncode(saveGame.toJson());
    final saveBytes = utf8.encode(saveJson);

    // Créer les métadonnées du fichier
    final fileName = 'save_${saveGame.id}.json';
    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = [_appFolderId!]
      ..mimeType = 'application/json';

    // Vérifier si le fichier existe déjà
    final existingFiles = await _driveApi!.files.list(
      q: "name='$fileName' and '${_appFolderId!}' in parents and trashed=false",
      $fields: 'files(id, name)',
    );

    final media = drive.Media(
      Stream.fromIterable([saveBytes]),
      saveBytes.length,
      contentType: 'application/json',
    );

    try {
      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Mettre à jour le fichier existant
        final fileId = existingFiles.files!.first.id!;
        await _driveApi!.files.update(fileMetadata, fileId, uploadMedia: media);
        saveGame.cloudId = fileId;
      } else {
        // Créer un nouveau fichier
        final createdFile = await _driveApi!.files.create(fileMetadata, uploadMedia: media);
        saveGame.cloudId = createdFile.id;
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde sur Drive: $e');
      // Tentative de récupération: essayer de créer un nouveau fichier si la mise à jour échoue
      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        try {
          final createdFile = await _driveApi!.files.create(fileMetadata, uploadMedia: media);
          saveGame.cloudId = createdFile.id;
        } catch (createError) {
          throw SaveError('CLOUD_SAVE_ERROR', 'Impossible de sauvegarder dans le cloud: $createError');
        }
      } else {
        throw SaveError('CLOUD_SAVE_ERROR', 'Impossible de sauvegarder dans le cloud: $e');
      }
    }
  }




  @override
  Future<SaveGame?> load(String cloudId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_driveApi != null && _appFolderId != null) {
        return await _loadFromDrive(cloudId);
      } else if (await _isPlayGamesAvailable()) {
        return await _loadFromPlayGames(cloudId);
      }

      return null;
    } catch (e, stack) {
      debugPrint('Erreur chargement cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  @override
  Future<List<SaveGameInfo>> listSaves() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_driveApi != null && _appFolderId != null) {
        return await _listDriveSaves();
      } else if (await _isPlayGamesAvailable()) {
        return await _listPlayGamesSaves();
      }

      return [];
    } catch (e, stack) {
      debugPrint('Erreur liste cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return [];
    }
  }

  @override
  Future<void> delete(String cloudId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_driveApi != null && _appFolderId != null) {
        await _deleteFromDrive(cloudId);
      } else if (await _isPlayGamesAvailable()) {
        await _deleteFromPlayGames(cloudId);
      }
    } catch (e, stack) {
      debugPrint('Erreur suppression cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String cloudId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_driveApi != null && _appFolderId != null) {
        return await _existsInDrive(cloudId);
      } else if (await _isPlayGamesAvailable()) {
        return await _existsInPlayGames(cloudId);
      }

      return false;
    } catch (e) {
      debugPrint('Erreur vérification existence cloud: $e');
      return false;
    }
  }





  Future<SaveGame?> _loadFromDrive(String cloudId) async {
    // Rechercher le fichier par son ID
    final fileId = cloudId.startsWith('save_') ? cloudId : 'save_$cloudId.json';

    try {
      final fileList = await _driveApi!.files.list(
        q: "name='$fileId' and '${_appFolderId!}' in parents and trashed=false",
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }

      // Télécharger le contenu
      final response = await _driveApi!.files.get(
        fileList.files!.first.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _mediaToBytes(response);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final saveGame = SaveGame.fromJson(json);
      saveGame.isSyncedWithCloud = true;
      saveGame.cloudId = fileList.files!.first.id;

      return saveGame;
    } catch (e) {
      debugPrint('Erreur chargement depuis Drive: $e');
      return null;
    }
  }

  Future<List<SaveGameInfo>> _listDriveSaves() async {
    try {
      final fileList = await _driveApi!.files.list(
        q: "name contains 'save_' and '${_appFolderId!}' in parents and trashed=false",
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return [];
      }

      final saves = <SaveGameInfo>[];

      for (final file in fileList.files!) {
        try {
          final response = await _driveApi!.files.get(
            file.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final bytes = await _mediaToBytes(response);
          final jsonString = utf8.decode(bytes);
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          // Extraire les données de sauvegarde
          final gameData = json['gameData'] as Map<String, dynamic>?;
          final playerData = gameData?['playerManager'] as Map<String, dynamic>?;

          saves.add(SaveGameInfo(
            id: json['id'] ?? file.id!,
            name: json['name'] ?? file.name!.replaceAll('save_', '').replaceAll('.json', ''),
            timestamp: DateTime.parse(json['timestamp'] as String? ?? file.modifiedTime!.toIso8601String()),
            version: json['version'] ?? GameConstants.VERSION,
            paperclips: _extractDouble(playerData, 'paperclips') ??
                _extractDouble(gameData?['productionManager'], 'paperclips') ?? 0.0,
            money: _extractDouble(playerData, 'money') ?? 0.0,
            isSyncedWithCloud: true,
            cloudId: file.id,
            gameMode: json['gameMode'] != null ?
            GameMode.values[json['gameMode'] as int] :
            GameMode.INFINITE,
          ));
        } catch (e) {
          debugPrint('Erreur lecture du fichier ${file.name}: $e');
        }
      }

      // Trier par date
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      debugPrint('Erreur liste Drive: $e');
      return [];
    }
  }

  Future<void> _deleteFromDrive(String cloudId) async {
    try {
      final fileId = cloudId.startsWith('save_') ? cloudId : 'save_$cloudId.json';

      final fileList = await _driveApi!.files.list(
        q: "name='$fileId' and '${_appFolderId!}' in parents and trashed=false",
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        await _driveApi!.files.delete(fileList.files!.first.id!);
      }
    } catch (e) {
      debugPrint('Erreur suppression Drive: $e');
      rethrow;
    }
  }

  Future<bool> _existsInDrive(String cloudId) async {
    try {
      final fileId = cloudId.startsWith('save_') ? cloudId : 'save_$cloudId.json';

      final fileList = await _driveApi!.files.list(
        q: "name='$fileId' and '${_appFolderId!}' in parents and trashed=false",
        $fields: 'files(id, name)',
      );

      return fileList.files != null && fileList.files!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Implémentation Google Play Games
  Future<bool> _isPlayGamesAvailable() async {
    try {
      return await gs.GamesServices.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveToPlayGames(SaveGame saveGame) async {
    try {
      // Note: Simplification de l'interface avec Games Services
      // Adaptez cette partie selon l'API réelle que vous utilisez
      final snapshot = '${CLOUD_SAVE_PREFIX}${saveGame.id}';
      final data = jsonEncode(saveGame.toJson());

      // Version simplifiée qui utilise GamesServices
      // Notez que Games Services 4.0.3 ne supporte pas directement ces opérations
      // Cette implémentation est un placeholder que vous devrez adapter
      await gs.GamesServices.signIn();

      // Ici, implémentez la logique de sauvegarde avec Games Services
      // Cette partie dépendra de l'API exacte que vous utilisez

      saveGame.cloudId = snapshot;
      saveGame.isSyncedWithCloud = true;
    } catch (e) {
      debugPrint('Erreur sauvegarde PlayGames: $e');
      rethrow;
    }
  }

  Future<SaveGame?> _loadFromPlayGames(String cloudId) async {
    try {
      // Note: Simplification de l'interface avec Games Services
      // Adaptez cette partie selon l'API réelle que vous utilisez
      await gs.GamesServices.signIn();

      // Ici, implémentez la logique de chargement avec Games Services
      // Cette partie dépendra de l'API exacte que vous utilisez

      return null; // Remplacer par l'implémentation réelle
    } catch (e) {
      debugPrint('Erreur chargement PlayGames: $e');
      return null;
    }
  }

  Future<List<SaveGameInfo>> _listPlayGamesSaves() async {
    // Implémentation à adapter selon l'API de Games Services
    return [];
  }

  Future<void> _deleteFromPlayGames(String cloudId) async {
    // Implémentation à adapter selon l'API de Games Services
  }

  Future<bool> _existsInPlayGames(String cloudId) async {
    // Implémentation à adapter selon l'API de Games Services
    return false;
  }

  // Utilitaires
  Future<List<int>> _mediaToBytes(drive.Media media) async {
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  double? _extractDouble(Map<String, dynamic>? data, String key) {
    if (data == null || !data.containsKey(key)) return null;
    final value = data[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try { return double.parse(value); } catch (_) { return null; }
    }
    return null;
  }
}

// Classe utilitaire pour créer un client HTTP authentifié
class _AuthClient extends http.BaseClient {
  final http.Client _client;
  final Map<String, String> _headers;

  _AuthClient(this._client, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}