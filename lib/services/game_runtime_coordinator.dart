import 'dart:async' show unawaited;
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart';
import 'auto_save_service.dart';
import '../controllers/game_session_controller.dart';
import 'lifecycle/app_lifecycle_handler.dart';
import '../gameplay/events/bus/game_event_bus.dart';
import '../gameplay/events/game_event.dart';
import 'persistence/game_persistence_orchestrator.dart';
import 'persistence/game_persistence_mapper.dart';
import 'metrics/runtime_metrics.dart';
import 'metrics/runtime_watchdog.dart';
import 'runtime/runtime_meta.dart';
import 'audio/game_audio_port.dart';
import 'runtime/clock.dart';
import 'runtime/runtime_orchestrator.dart';
import 'offline_progress_service.dart';
import '../utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'auth/firebase_auth_service.dart';
import 'persistence/last_played_tracker.dart';

class GameRuntimeCoordinator implements RuntimeOrchestrator {
  final GameState _gameState;
  final AppLifecycleHandler _lifecycleHandler;
  final AutoSaveService _autoSaveService;
  final GameSessionController _gameSessionController;
  final Clock _clock;
  final Logger _logger = Logger.forComponent('runtime');
  bool _isRecoveringOffline = false;
  GameEventListener? _eventListener;
  GameAudioPort? _audioPort;
  void Function(OfflineProgressResult)? _onOfflineProgressCallback;

  GameRuntimeCoordinator({
    required GameState gameState,
    required AppLifecycleHandler lifecycleHandler,
    required AutoSaveService autoSaveService,
    required GameSessionController gameSessionController,
    Clock? clock,
  })  : _gameState = gameState,
        _lifecycleHandler = lifecycleHandler,
        _autoSaveService = autoSaveService,
        _gameSessionController = gameSessionController,
        _clock = clock ?? SystemClock();

  Future<void> register() async {
    _lifecycleHandler.setOnLifecycleResume(_onAppResumed);
    _lifecycleHandler.setOnLifecycleSave(({required String reason}) async {
      // Met la session en pause pour garantir aucune progression pendant la sauvegarde
      _gameSessionController.pauseSession();
      // Met à jour le runtime meta et déclenche une sauvegarde de cycle de vie
      final now = _clock.now();
      RuntimeMetaRegistry.instance.setLastActiveAt(now);
      // Propage aussi vers GameState pour que toSnapshot() reflète les métadonnées
      _gameState.markLastActiveAt(now);
      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        _gameState,
        reason: reason,
      );
      // CORRECTION: Push cloud supprimé ici - géré automatiquement par _pump() après la sauvegarde
    });
    _lifecycleHandler.register(_gameState);
    _attachEventListeners();
  }

  void unregister() {
    _lifecycleHandler.unregister();
    _detachEventListeners();
  }

  void startSession() {
    _gameSessionController.startSession();
  }

  void stopSession() {
    _gameSessionController.stopSession();
  }

  @override
  void start() {
    startSession();
    unawaited(startAutoSave());
  }

  @override
  void stop() {
    unawaited(stopAutoSave());
    // CORRECTION: Push cloud supprimé ici - géré par lifecycle save lors de app pause/inactive
    stopSession();
  }

  @override
  void pause() {
    // Log simple pour observabilité
    if (kDebugMode) _logger.debug('[Runtime] pause() called');
    RuntimeMetrics.recordPause();
    _gameSessionController.pauseSession();
  }

  @override
  void resume() {
    if (kDebugMode) _logger.debug('[Runtime] resume() called');
    RuntimeMetrics.recordResume();
    _gameSessionController.resumeSession();
  }

  @override
  Future<void> recoverOffline() async {
    if (_isRecoveringOffline) {
      if (kDebugMode) _logger.debug('[Runtime] recoverOffline() skipped (already running)');
      return;
    }
    _isRecoveringOffline = true;
    try {
      final start = _clock.now();
      final result = _applyOfflineProgress(now: start);
      final end = _clock.now();
      if (kDebugMode) _logger.debug('[Runtime] recoverOffline() completed in ${end.difference(start).inMilliseconds} ms');
      RuntimeMetrics.recordRecoverOffline(
        durationMs: end.difference(start).inMilliseconds,
        didSimulate: result.didSimulate,
      );
    } finally {
      _isRecoveringOffline = false;
    }
  }

  Future<void> startAutoSave() async {
    await _autoSaveService.start();
  }

  Future<void> stopAutoSave() async {
    _autoSaveService.stop();
  }

  // Legacy supprimé: loadGameAndStartAutoSave(name) retiré (ID-first uniquement)

  Future<void> loadGameByIdAndStartAutoSave(String id) async {
    // CORRECTION BUG: Arrêter proprement la session en cours avant le switch
    stopSession();
    _autoSaveService.stop();
    try {
      // [WORLD-SWITCH] before loading new world
      final prevId = _gameState.enterpriseId ?? '';
      _logger.info('[WORLD-SWITCH] before', code: 'world_switch_before', ctx: {
        'from': prevId,
        'to': id,
        'reason': 'user_load',
      });
    } catch (_) {}
    
    try {
      await GamePersistenceOrchestrator.instance.loadGameById(_gameState, id);
    } catch (e, stack) {
      // CORRECTION: Gestion d'erreur complète avec logs détaillés
      _logger.error('[WORLD-SWITCH] Échec chargement', code: 'world_switch_load_error', ctx: {
        'enterpriseId': id,
        'error': e.toString(),
        'stack': stack.toString().substring(0, stack.toString().length > 300 ? 300 : stack.toString().length),
      });
      
      // Log [WORLD-SWITCH] after même en cas d'erreur pour traçabilité
      try {
        _logger.info('[WORLD-SWITCH] after (failed)', code: 'world_switch_after', ctx: {
          'to': id,
          'reason': 'user_load',
          'success': false,
        });
      } catch (_) {}
      
      rethrow;
    }
    
    await _autoSaveService.start();
    
    // Enregistrer comme dernière partie jouée
    try {
      await LastPlayedTracker.instance.setLastPlayed(id);
    } catch (_) {}
    
    // Après chargement local, vérifier l'état cloud et importer si le cloud est en avance.
    // Appel non bloquant: l'orchestrateur gère l'identité et les erreurs réseau.
    unawaited(GamePersistenceOrchestrator.instance.checkCloudAndPullIfNeeded(
      state: _gameState,
      enterpriseId: id,
    ));
    final audio = _audioPort;
    if (audio != null) {
      // Charger l'état audio associé à l'entreprise (utiliser le nom résolu après chargement)
      final name = _gameState.enterpriseName ?? '';
      if (name.isNotEmpty) {
        unawaited(audio.loadGameMusicState(name));
      }
    }
    try {
      // [WORLD-SWITCH] after loading new world
      final newId = _gameState.enterpriseId ?? id;
      _logger.info('[WORLD-SWITCH] after', code: 'world_switch_after', ctx: {
        'to': newId,
        'reason': 'user_load',
        'success': true,
      });
    } catch (_) {}
    
    // Enregistrer comme dernière partie jouée
    try {
      await LastPlayedTracker.instance.setLastPlayed(id);
    } catch (_) {}
  }

  // CHANTIER-01: Créer une nouvelle entreprise
  Future<void> createNewEnterpriseAndStartAutoSave(String enterpriseName) async {
    _autoSaveService.stop();
    
    try {
      _logger.info('Creating new enterprise', code: 'enterprise_create_start', ctx: {
        'name': enterpriseName,
      });
      
      // Créer l'entreprise dans GameState
      await _gameState.createNewEnterprise(enterpriseName);
      
      final enterpriseId = _gameState.enterpriseId;
      if (enterpriseId == null || enterpriseId.isEmpty) {
        throw StateError('Enterprise ID missing after creation');
      }
      
      _logger.info('Enterprise created', code: 'enterprise_created', ctx: {
        'enterpriseId': enterpriseId,
        'enterpriseName': enterpriseName,
      });
      
      // Sauvegarde locale immédiate
      await GamePersistenceOrchestrator.instance.saveGameById(_gameState);
      
    } catch (e, stack) {
      _logger.error('Failed to create enterprise', code: 'enterprise_create_failed', ctx: {
        'error': e.toString(),
        'stack': stack.toString(),
      });
      rethrow;
    }
    
    await _autoSaveService.start();
    
    final audio = _audioPort;
    if (audio != null && enterpriseName.isNotEmpty) {
      unawaited(audio.loadGameMusicState(enterpriseName));
    }
    
    // Cloud push si connecté
    try {
      final firebaseUser = FirebaseAuthService.instance.currentUser;
      if (firebaseUser != null) {
        _logger.debug('[Runtime] Pushing new enterprise to cloud');
        unawaited(
          GamePersistenceOrchestrator.instance.saveOnImportantEvent(_gameState),
        );
      }
    } catch (_) {}
  }

  // CHANTIER-01: Charger l'entreprise unique
  Future<void> loadEnterpriseAndStartAutoSave() async {
    stopSession();
    _autoSaveService.stop();
    
    try {
      // Charger l'entreprise par son ID
      final enterpriseId = _gameState.enterpriseId;
      if (enterpriseId == null || enterpriseId.isEmpty) {
        throw StateError('No enterprise ID found');
      }
      await GamePersistenceOrchestrator.instance.loadGameById(_gameState, enterpriseId);
      
      _logger.info('Enterprise loaded', code: 'enterprise_loaded', ctx: {
        'enterpriseId': _gameState.enterpriseId,
        'enterpriseName': _gameState.enterpriseName,
      });
    } catch (e, stack) {
      _logger.error('Failed to load enterprise', code: 'enterprise_load_failed', ctx: {
        'error': e.toString(),
        'stack': stack.toString(),
      });
      rethrow;
    }
    
    await _autoSaveService.start();
    
    final audio = _audioPort;
    if (audio != null) {
      final name = _gameState.enterpriseName;
      if (name != null && name.isNotEmpty) {
        unawaited(audio.loadGameMusicState(name));
      }
    }
    
    // Cloud sync si connecté
    try {
      final enableCloud = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
      final eid = _gameState.enterpriseId;
      if (enableCloud && eid != null && eid.isNotEmpty) {
        unawaited(
          GamePersistenceOrchestrator.instance.checkCloudAndPullIfNeeded(
            state: _gameState,
            enterpriseId: eid,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> startNewGameAndStartAutoSave(
    String name,
  ) async {
    _autoSaveService.stop();
    // Mission: snapshot des mondes présents avant la création de B
    try {
      final saves = await GamePersistenceOrchestrator.instance.listSaves();
      final ids = saves
          .where((m) => !m.name.contains(GameConstants.BACKUP_DELIMITER))
          .map((m) => m.id)
          .toList();
      _logger.info('📃 WORLDS-SNAPSHOT', code: 'worlds_snapshot_before', ctx: {
        'count': ids.length,
        'ids': ids.join(','),
      });
    } catch (_) {}
    try {
      // [WORLD-CREATE] before creation
      final beforeId = _gameState.enterpriseId ?? '';
      _logger.info('[WORLD-CREATE] before', code: 'world_create_before', ctx: {
        'prev_enterpriseId': beforeId,
        'origin': 'new_game',
        'name': name,
      });
    } catch (_) {}
    await _gameState.startNewGame(name);
    // Invariant identité: une entreprise doit posséder un enterpriseId unique dès sa création
    final newEnterpriseId = _gameState.enterpriseId;
    if (newEnterpriseId == null || newEnterpriseId.isEmpty) {
      // Verrouillage strict: interdire toute suite (autosave/sync) sans identité
      throw StateError('[IdentityInvariant] enterpriseId manquant après startNewGame("'+name+'"): création invalide');
    }
    try {
      // [WORLD-CREATE] after creation
      _logger.info('[WORLD-CREATE] after', code: 'world_create_after', ctx: {
        'enterpriseId': newEnterpriseId,
        'origin': 'new_game',
        'name': name,
      });
    } catch (_) {}
    
    // CORRECTION CRITIQUE #1: Sauvegarde locale immédiate après création
    // Garantit que le monde est persisté même si crash avant premier autosave
    try {
      _logger.info('[WORLD-CREATE] Sauvegarde locale immédiate', code: 'world_create_initial_save', ctx: {
        'enterpriseId': newEnterpriseId,
      });
      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        _gameState,
        reason: 'world_creation_initial',
      );
    } catch (e) {
      _logger.error('[WORLD-CREATE] Échec sauvegarde locale initiale: $e', code: 'world_create_save_failed');
      // Lever l'exception car un monde non sauvegardé est un état invalide
      throw StateError('[WorldCreation] Impossible de sauvegarder le nouveau monde: $e');
    }
    
    await _autoSaveService.start();
    
    // Enregistrer comme dernière partie jouée
    try {
      await LastPlayedTracker.instance.setLastPlayed(newEnterpriseId);
    } catch (_) {}
    
    final audio = _audioPort;
    if (audio != null) {
      unawaited(audio.loadGameMusicState(name));
    }

    // Mission 4: Cloud obligatoire si connecté (push garanti pour utilisateur authentifié)
    try {
      // Push obligatoire si utilisateur Firebase connecté, indépendamment de cloud_enabled
      final firebaseUser = FirebaseAuthService.instance.currentUser;
      if (firebaseUser != null) {
        if (kDebugMode) {
          _logger.debug('[Runtime] User authenticated (uid=${firebaseUser.uid}) - pushing new world to cloud');
        }
        // CORRECTION: Push cloud immédiat pour création de monde (événement critique)
        // Ce push est intentionnel et ne passe pas par la queue pour garantir la synchronisation
        await GamePersistenceOrchestrator.instance.pushCloudForState(_gameState, reason: 'world_creation');
      } else {
        if (kDebugMode) {
          _logger.debug('[Runtime] User not authenticated - skipping cloud push for new world');
        }
      }
    } catch (e) {
      // Logger l'erreur mais ne pas bloquer la création du monde
      _logger.warn('[Runtime] Failed to push new world to cloud: $e', code: 'world_creation_push_failed');
    }
  }

  // Legacy supprimé: manualSave(name) retiré (ID-first uniquement)

  void _attachEventListeners() {
    _eventListener ??= (event) => _onGameEvent(event);
    _gameState.addEventListener(_eventListener!);
  }

  void _detachEventListeners() {
    final listener = _eventListener;
    if (listener != null) {
      _gameState.removeEventListener(listener);
    }
  }

  // Injection tardive du port audio depuis le bootstrap
  void setAudioPort(GameAudioPort port) {
    _audioPort = port;
  }

  // Injection du callback pour afficher la notification offline
  void setOfflineProgressCallback(void Function(OfflineProgressResult) callback) {
    _onOfflineProgressCallback = callback;
  }

  void _onGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.autoclipperPurchased:
        // Post-frame + coalescing: déclenche une autosave légère pour éviter un freeze UI au clic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
            GamePersistenceOrchestrator.instance.requestAutoSave(
              _gameState,
              reason: 'autoclipper_purchased',
            ),
          );
        });
        return;
      case GameEventType.importantEventOccurred:
        final reason = event.data['reason'] as String?;
        if (reason == 'offline_progress_request') {
          final nowOverrideIso = event.data['nowOverride'] as String?;
          final now = nowOverrideIso != null ? DateTime.tryParse(nowOverrideIso) ?? _clock.now() : _clock.now();
          _applyOfflineProgress(now: now);
        } else {
          // Déclenche l'autosave via l'orchestrateur (fire-and-forget) + métriques
          final sw = Stopwatch()..start();
          RuntimeMetrics.recordAutosaveTriggered();
          unawaited(
            GamePersistenceOrchestrator.instance.saveOnImportantEvent(_gameState).then((_) {
              sw.stop();
              final dur = sw.elapsedMilliseconds;
              RuntimeMetrics.recordAutosaveCompleted(durationMs: dur, success: true);
              RuntimeWatchdog.evaluateAutosave(durationMs: dur, success: true);
            }).catchError((_) {
              sw.stop();
              final dur = sw.elapsedMilliseconds;
              RuntimeMetrics.recordAutosaveCompleted(durationMs: dur, success: false);
              RuntimeWatchdog.evaluateAutosave(durationMs: dur, success: false);
            }),
          );
        }
        return;
      default:
        return;
    }
  }

  void _onAppResumed() {
    // Applique d'abord l'offline, puis reprend la session
    final now = _clock.now();
    final result = _applyOfflineProgress(now: now);
    
    // Afficher la notification si l'utilisateur était absent et qu'un callback est configuré
    if (result.didSimulate && _onOfflineProgressCallback != null) {
      _onOfflineProgressCallback!(result);
    }
    
    try {
      final enableCloud = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
      final pid = _gameState.enterpriseId;
      if (enableCloud && pid != null && pid.isNotEmpty) {
        unawaited(
          GamePersistenceOrchestrator.instance.checkCloudAndPullIfNeeded(
            state: _gameState,
            enterpriseId: pid,
          ),
        );
      }
    } catch (_) {}
    _gameSessionController.resumeSession();
  }

  OfflineProgressResult _applyOfflineProgress({required DateTime now}) {
    // Lire les métadonnées actuelles depuis le registre runtime (hors GameState)
    final meta = RuntimeMetaRegistry.instance;
    final lastActiveAt = meta.lastActiveAt;
    final lastOfflineAppliedAt = meta.lastOfflineAppliedAt;

    // Délègue le calcul/simulation à OfflineProgressService via GameState
    final result = _gameState.applyOfflineWithService(
      now: now,
      lastActiveAt: lastActiveAt,
      lastOfflineAppliedAt: lastOfflineAppliedAt,
    );

    // Met à jour les métadonnées runtime et domaine à partir du résultat
    meta.setLastActiveAt(result.lastActiveAt);
    meta.setLastOfflineAppliedAt(result.lastOfflineAppliedAt);
    meta.setOfflineSpecVersion(result.offlineSpecVersion);
    _gameState.markLastActiveAt(result.lastActiveAt);
    _gameState.markLastOfflineAppliedAt(result.lastOfflineAppliedAt);
    _gameState.markOfflineSpecVersion(result.offlineSpecVersion);

    // Best-effort: sauvegarde si une simulation a été effectuée
    if (result.didSimulate) {
      unawaited(
        GamePersistenceOrchestrator.instance.saveOnImportantEvent(_gameState),
      );
    }
    return result;
  }
}
