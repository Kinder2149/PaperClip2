// lib/data/models/market_model.dart
import 'package:paperclip2/domain/entities/market_entity.dart';
import 'sale_record_model.dart';

class MarketModel {
  final double marketMetalStock;
  final double reputation;
  final double currentMetalPrice;
  final List<SaleRecordModel> salesHistory;

  MarketModel({
    required this.marketMetalStock,
    required this.reputation,
    required this.currentMetalPrice,
    required this.salesHistory,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    List<SaleRecordModel> sales = [];
    if (json['salesHistory'] != null) {
      sales = (json['salesHistory'] as List)
          .map((saleJson) => SaleRecordModel.fromJson(saleJson))
          .toList();
    }

    return MarketModel(
      marketMetalStock: (json['marketMetalStock'] as num?)?.toDouble() ?? 80000.0,
      reputation: (json['reputation'] as num?)?.toDouble() ?? 1.0,
      currentMetalPrice: (json['currentMetalPrice'] as num?)?.toDouble() ?? 15.0,
      salesHistory: sales,
    );
  }

  Map<String, dynamic> toJson() => {
    'marketMetalStock': marketMetalStock,
    'reputation': reputation,
    'currentMetalPrice': currentMetalPrice,
    'salesHistory': salesHistory.map((sale) => sale.toJson()).toList(),
  };

  MarketEntity toEntity() {
    return MarketEntity(
      marketMetalStock: marketMetalStock,
      reputation: reputation,
      currentMetalPrice: currentMetalPrice,
      salesHistory: salesHistory.map((sale) => sale.toEntity()).toList(),
    );
  }

  static MarketModel fromEntity(MarketEntity entity) {
    return MarketModel(
      marketMetalStock: entity.marketMetalStock,
      reputation: entity.reputation,
      currentMetalPrice: entity.currentMetalPrice,
      salesHistory: entity.salesHistory.map((sale) => SaleRecordModel.fromEntity(sale)).toList(),
    );
  }
}
