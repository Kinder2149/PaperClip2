// lib/presentation/viewmodels/upgrades_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:paperclip2/domain/repositories/player_repository.dart';
import 'package:paperclip2/domain/entities/player_entity.dart';
import 'package:paperclip2/domain/entities/upgrade_entity.dart';
import 'package:paperclip2/domain/repositories/upgrades_repository.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/upgrade.dart';
import '../../domain/entities/upgrade_category.dart';

class UpgradesViewModel extends ChangeNotifier {
  final PlayerRepository _playerRepository;
  final UpgradesRepository _upgradesRepository;

  PlayerEntity? _playerState;
  bool _isLoading = false;
  String? _error;
  List<UpgradeCategory> _categories = [];
  UpgradeCategory? _selectedCategory;
  List<Upgrade> _upgrades = [];

  UpgradesViewModel({
    required PlayerRepository playerRepository,
    required UpgradesRepository upgradesRepository,
  })
      : _playerRepository = playerRepository,
        _upgradesRepository = upgradesRepository {
    _loadPlayerState();
    _loadInitialData();
  }

  PlayerEntity? get playerState => _playerState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, UpgradeEntity> get upgrades => _playerState?.upgrades ?? {};
  List<UpgradeCategory> get categories => _categories;
  UpgradeCategory? get selectedCategory => _selectedCategory;
  List<Upgrade> get upgradesList => _upgrades;

  Future<void> _loadPlayerState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playerState = await _playerRepository.getPlayerState();
    } catch (e) {
      _error = 'Erreur lors du chargement des données: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _upgradesRepository.getCategories();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        await _loadUpgradesForCategory(_selectedCategory!.id);
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des améliorations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String categoryId) async {
    _selectedCategory = _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => _categories.first,
    );
    await _loadUpgradesForCategory(categoryId);
    notifyListeners();
  }

  Future<void> _loadUpgradesForCategory(String categoryId) async {
    try {
      _upgrades = await _upgradesRepository.getUpgradesForCategory(categoryId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des améliorations: $e';
      notifyListeners();
    }
  }

  List<Upgrade> getUpgradesForCategory(String categoryId) {
    return _upgrades.where((upgrade) => upgrade.categoryId == categoryId).toList();
  }

  Future<bool> purchaseUpgrade(String upgradeId) async {
    if (_isLoading) return false;

    try {
      final upgrade = _upgrades.firstWhere((u) => u.id == upgradeId);
      if (!upgrade.canAfford || upgrade.isMaxed) return false;

      await _upgradesRepository.purchaseUpgrade(upgradeId);
      await _loadUpgradesForCategory(upgrade.categoryId);
      await _loadPlayerState();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'achat de l\'amélioration: $e';
      notifyListeners();
      return false;
    }
  }

  bool canAffordUpgrade(String upgradeId) {
    if (_playerState == null) return false;

    final upgrade = _playerState!.upgrades[upgradeId];
    if (upgrade == null) return false;

    return _playerState!.money >= upgrade.getCost() && upgrade.level < upgrade.maxLevel;
  }

  void retry() {
    _loadInitialData();
  }
}