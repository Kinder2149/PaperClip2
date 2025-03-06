// lib/presentation/viewmodels/game_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:paperclip2/domain/usecases/game/save_game_usecase.dart';
import 'package:paperclip2/domain/usecases/game/load_game_usecase.dart';
import 'package:paperclip2/domain/repositories/game_repository.dart';
import 'package:paperclip2/domain/entities/game_state_entity.dart';
import '../../domain/entities/game_save.dart';
import '../../domain/repositories/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/event_service.dart';
import '../../domain/services/reward_service.dart';

class GameViewModel extends ChangeNotifier {
  final SaveGameUseCase _saveGameUseCase;
  final LoadGameUseCase _loadGameUseCase;
  final GameRepository _gameRepository;
  final SaveRepository _saveRepository;

  GameStateEntity? _gameState;
  bool _isLoading = false;
  String? _error;
  String? _currentGameName;

  List<GameSave> _availableSaves = [];

  // Paramètres du jeu
  bool _autoSaveEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  final NotificationService _notificationService = NotificationService();
  final EventService _eventService = EventService();
  final RewardService _rewardService = RewardService();

  List<GameEvent> get activeEvents => _eventService.activeEvents;
  List<Reward> get availableRewards => _rewardService.availableRewards;

  GameViewModel({
    required SaveGameUseCase saveGameUseCase,
    required LoadGameUseCase loadGameUseCase,
    required GameRepository gameRepository,
    required SaveRepository saveRepository,
  })
      : _saveGameUseCase = saveGameUseCase,
        _loadGameUseCase = loadGameUseCase,
        _gameRepository = gameRepository,
        _gameRepository = gameRepository;

  GameStateEntity? get gameState => _gameState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentGameName => _currentGameName;

  bool get autoSaveEnabled => _autoSaveEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> saveGame(String name) async {
    if (_isLoading || _gameState == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _saveGameUseCase.execute(name);
      _currentGameName = name;
    } catch (e) {
      _error = 'Erreur lors de la sauvegarde: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadGame(String name) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loadedState = await _loadGameUseCase.execute(name);
      if (loadedState != null) {
        _gameState = loadedState;
        _currentGameName = name;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void processTick() {
    // Logique de mise à jour du jeu à chaque tick
  }

  void incrementPlayTime(int seconds) {
    if (_gameState != null) {
      _gameState = _gameState!.copyWith(
          totalTimePlayedInSeconds: _gameState!.totalTimePlayedInSeconds + seconds
      );
      notifyListeners();
    }
  }

  void autoSaveGame() {
    if (_gameState != null && _currentGameName != null) {
      saveGame(_currentGameName!);
    }
  }

  Future<List<SaveGameInfo>> listSaves() async {
    try {
      return await _gameRepository.listSaves();
    } catch (e) {
      _error = 'Erreur lors de la récupération des sauvegardes: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> deleteSave(String name) async {
    try {
      return await _gameRepository.deleteSave(name);
    } catch (e) {
      _error = 'Erreur lors de la suppression de la sauvegarde: $e';
      notifyListeners();
      return false;
    }
  }

  void updateGameState(GameStateEntity newState) {
    _gameState = newState;
    notifyListeners();
  }

  // Méthodes pour gérer les paramètres
  Future<void> setAutoSave(bool value) async {
    _autoSaveEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _soundEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    _musicEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  // Sauvegarder les paramètres
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_save', _autoSaveEnabled);
      await prefs.setBool('notifications', _notificationsEnabled);
      await prefs.setBool('dark_mode', _darkModeEnabled);
      await prefs.setBool('sound', _soundEnabled);
      await prefs.setBool('music', _musicEnabled);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  // Charger les paramètres
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSaveEnabled = prefs.getBool('auto_save') ?? true;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      _soundEnabled = prefs.getBool('sound') ?? true;
      _musicEnabled = prefs.getBool('music') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  @override
  Future<void> initialize() async {
    await _loadSettings();
    await _notificationService.initialize();
    await _eventService.initialize();
    await _rewardService.initialize();
  }

  // Méthodes pour les notifications
  Future<void> showNotification(String title, String body) async {
    if (_notificationsEnabled) {
      await _notificationService.showNotification(
        title: title,
        body: body,
      );
    }
  }

  // Méthodes pour les événements
  Future<void> addEvent(GameEvent event) async {
    await _eventService.addEvent(event);
    notifyListeners();
  }

  Future<void> completeEvent(String eventId) async {
    await _eventService.completeEvent(eventId);
    notifyListeners();
  }

  // Méthodes pour les récompenses
  Future<void> addReward(Reward reward) async {
    await _rewardService.addReward(reward);
    notifyListeners();
  }

  Future<void> claimReward(String rewardId) async {
    await _rewardService.claimReward(rewardId);
    notifyListeners();
  }

  @override
  void dispose() {
    _eventService.dispose();
    _rewardService.dispose();
    super.dispose();
  }
}