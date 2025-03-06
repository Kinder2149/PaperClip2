// lib/data/datasources/local/market_data_source.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/market_model.dart';
import '../../models/sale_record_model.dart';
import '../../../core/constants/game_constants.dart';

abstract class MarketDataSource {
  Future<MarketModel> getMarketState();
  Future<void> updateMarketState(MarketModel marketState);
  Future<List<SaleRecordModel>> getSalesHistory();
  Future<void> recordSale(SaleRecordModel sale);
  Future<double> getCurrentMetalPrice();
  Future<void> updateMetalPrice(double newPrice);
}

class MarketDataSourceImpl implements MarketDataSource {
  final SharedPreferences _prefs;
  static const String _marketStateKey = 'market_state';
  static const String _salesHistoryKey = 'sales_history';

  MarketDataSourceImpl(this._prefs);

  @override
  Future<MarketModel> getMarketState() async {
    final jsonString = _prefs.getString(_marketStateKey);

    if (jsonString == null) {
      // Retourne un état de marché par défaut si aucune sauvegarde n'existe
      return MarketModel(
        marketMetalStock: GameConstants.INITIAL_MARKET_METAL,
        reputation: 1.0,
        currentMetalPrice: GameConstants.MIN_METAL_PRICE,
        salesHistory: [],
      );
    }

    return MarketModel.fromJson(json.decode(jsonString));
  }

  @override
  Future<void> updateMarketState(MarketModel marketState) async {
    await _prefs.setString(
        _marketStateKey,
        json.encode(marketState.toJson())
    );
  }

  @override
  Future<List<SaleRecordModel>> getSalesHistory() async {
    final jsonString = _prefs.getString(_salesHistoryKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((saleJson) => SaleRecordModel.fromJson(saleJson))
        .toList();
  }

  @override
  Future<void> recordSale(SaleRecordModel sale) async {
    final currentHistory = await getSalesHistory();

    // Ajoute la nouvelle vente
    currentHistory.add(sale);

    // Limite l'historique à un nombre maximum de ventes
    if (currentHistory.length > GameConstants.MAX_SALES_HISTORY) {
      currentHistory.removeAt(0);
    }

    // Sauvegarde l'historique mis à jour
    await _prefs.setString(
        _salesHistoryKey,
        json.encode(currentHistory.map((sale) => sale.toJson()).toList())
    );
  }

  @override
  Future<double> getCurrentMetalPrice() async {
    final marketState = await getMarketState();
    return marketState.currentMetalPrice;
  }

  @override
  Future<void> updateMetalPrice(double newPrice) async {
    final currentMarketState = await getMarketState();
    final updatedMarketState = currentMarketState.copyWith(
        currentMetalPrice: newPrice
    );

    await updateMarketState(updatedMarketState);
  }
}