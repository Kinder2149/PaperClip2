// lib/data/models/sale_record_model.dart
import 'package:paperclip2/domain/entities/market_entity.dart';

class SaleRecordModel {
  final DateTime timestamp;
  final int quantity;
  final double price;
  final double revenue;

  SaleRecordModel({
    required this.timestamp,
    required this.quantity,
    required this.price,
    required this.revenue,
  });

  factory SaleRecordModel.fromJson(Map<String, dynamic> json) {
    return SaleRecordModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'quantity': quantity,
    'price': price,
    'revenue': revenue,
  };

  SaleRecord toEntity() {
    return SaleRecord(
      timestamp: timestamp,
      quantity: quantity,
      price: price,
      revenue: revenue,
    );
  }

  static SaleRecordModel fromEntity(SaleRecord entity) {
    return SaleRecordModel(
      timestamp: entity.timestamp,
      quantity: entity.quantity,
      price: entity.price,
      revenue: entity.revenue,
    );
  }
}