// lib/data/datasources/local/market_data_source_impl.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'market_data_source.dart';
import '../../models/market_model.dart';
import '../../models/sale_record_model.dart';
import '../../../core/constants/game_constants.dart';

class MarketDataSourceImpl implements MarketDataSource {
  final SharedPreferences _prefs;
  static const String _marketStateKey = 'market_state';
  static const String _salesHistoryKey = 'sales_history';
  static const String _metalPriceKey = 'current_metal_price';

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

    try {
      return MarketModel.fromJson(json.decode(jsonString));
    } catch (e) {
      print('Error parsing market state: $e');
      // En cas d'erreur, retourner l'état par défaut
      return MarketModel(
        marketMetalStock: GameConstants.INITIAL_MARKET_METAL,
        reputation: 1.0,
        currentMetalPrice: GameConstants.MIN_METAL_PRICE,
        salesHistory: [],
      );
    }
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

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((saleJson) => SaleRecordModel.fromJson(saleJson))
          .toList();
    } catch (e) {
      print('Error parsing sales history: $e');
      return [];
    }
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

    // Mettre à jour l'état du marché pour refléter la vente
    final marketState = await getMarketState();
    final updatedMarketState = marketState.copyWith(
      salesHistory: currentHistory,
    );

    await updateMarketState(updatedMarketState);
  }

  @override
  Future<double> getCurrentMetalPrice() async {
    final double? price = _prefs.getDouble(_metalPriceKey);
    return price ?? GameConstants.MIN_METAL_PRICE;
  }

  @override
  Future<void> updateMetalPrice(double newPrice) async {
    // Enregistrer le nouveau prix
    await _prefs.setDouble(_metalPriceKey, newPrice);

    // Mettre également à jour le modèle de marché
    final currentMarketState = await getMarketState();
    final updatedMarketState = currentMarketState.copyWith(
        currentMetalPrice: newPrice
    );

    await updateMarketState(updatedMarketState);
  }
}