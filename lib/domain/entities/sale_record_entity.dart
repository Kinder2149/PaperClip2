// lib/domain/entities/sale_record_entity.dart

class SaleRecordEntity {
  final DateTime timestamp;
  final int quantity;
  final double price;
  final double revenue;

  const SaleRecordEntity({
    required this.timestamp,
    required this.quantity,
    required this.price,
    required this.revenue,
  });

  SaleRecordEntity copyWith({
    DateTime? timestamp,
    int? quantity,
    double? price,
    double? revenue,
  }) {
    return SaleRecordEntity(
      timestamp: timestamp ?? this.timestamp,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      revenue: revenue ?? this.revenue,
    );
  }
}