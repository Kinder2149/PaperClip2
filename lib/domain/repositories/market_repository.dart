abstract class MarketRepository {
  Future<Market> getMarket();
  Future<void> updateMarket(Market market);
  Future<double> calculateDemand(double price, int marketingLevel);
  Future<void> updateMarketStock(double amount);
  Future<void> recordSale(int quantity, double price);
  Future<double> updateMetalPrice();
  Future<bool> isPriceExcessive(double price);
  Future<void> updateMarketConditions();
  Future<List<SaleRecord>> getSalesHistory();
}