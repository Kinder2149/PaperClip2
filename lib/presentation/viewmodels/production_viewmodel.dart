// lib/presentation/viewmodels/production_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/usecases/production/produce_clip_use_case.dart';
import '../../domain/usecases/production/toggle_auto_production_use_case.dart';
import '../../domain/usecases/production/buy_autoclipper_use_case.dart';

class ProductionViewModel extends ChangeNotifier {
  final ProduceClipUseCase _produceClipUseCase;
  final ToggleAutoProductionUseCase _toggleAutoProductionUseCase;
  final BuyAutoclipperUseCase _buyAutoclipperUseCase;

  PlayerState? _playerState;
  bool _isLoading = false;
  String? _error;

  ProductionViewModel({
    required ProduceClipUseCase produceClipUseCase,
    required ToggleAutoProductionUseCase toggleAutoProductionUseCase,
    required BuyAutoclipperUseCase buyAutoclipperUseCase,
  }) : _produceClipUseCase = produceClipUseCase,
       _toggleAutoProductionUseCase = toggleAutoProductionUseCase,
       _buyAutoclipperUseCase = buyAutoclipperUseCase;

  PlayerState? get playerState => _playerState;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlayerState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implémenter le chargement de l'état du joueur
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> produceClip() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _produceClipUseCase.execute();
      if (success) {
        await loadPlayerState();
      } else {
        _error = 'Impossible de produire un trombone';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAutoProduction() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _toggleAutoProductionUseCase.execute();
      if (success) {
        await loadPlayerState();
      } else {
        _error = 'Impossible de basculer la production automatique';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyAutoclipper() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _buyAutoclipperUseCase.execute();
      if (success) {
        await loadPlayerState();
      } else {
        _error = 'Impossible d\'acheter une autotromboneuse';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}