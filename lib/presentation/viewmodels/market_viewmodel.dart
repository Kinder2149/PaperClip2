// lib/presentation/viewmodels/market_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/market_state.dart';
import '../../domain/usecases/market/sell_clips_use_case.dart';
import '../../domain/usecases/market/buy_metal_use_case.dart';

class MarketViewModel extends ChangeNotifier {
  final SellClipsUseCase _sellClipsUseCase;
  final BuyMetalUseCase _buyMetalUseCase;

  MarketState? _marketState;
  bool _isLoading = false;
  String? _error;

  MarketViewModel({
    required SellClipsUseCase sellClipsUseCase,
    required BuyMetalUseCase buyMetalUseCase,
  }) : _sellClipsUseCase = sellClipsUseCase,
       _buyMetalUseCase = buyMetalUseCase;

  MarketState? get marketState => _marketState;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMarketState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implémenter le chargement de l'état du marché
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sellClips(int amount) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _sellClipsUseCase.execute(amount);
      if (success) {
        await loadMarketState();
      } else {
        _error = 'Impossible de vendre les trombones';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sellAllClips() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implémenter la vente de tous les trombones
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyMetal(int amount) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _buyMetalUseCase.execute(amount);
      if (success) {
        await loadMarketState();
      } else {
        _error = 'Impossible d\'acheter du métal';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}