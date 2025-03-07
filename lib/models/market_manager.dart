import 'interfaces/market_manager_interface.dart';
import 'constants/game_constants.dart';

class MarketManager implements IMarketManager {
  double _reputation = 1.0;

  @override
  double get reputation => _reputation;

  @override
  void updateReputation(double amount) {
    _reputation = (_reputation + amount).clamp(0.0, 2.0);
  }

  @override
  void updateMarketManagerState() {
    // Mise à jour périodique de la réputation basée sur les performances
    double performance = 0.0;
    // TODO: Calculer la performance basée sur les ventes et la satisfaction des clients
    updateReputation(performance * GameConstants.REPUTATION_IMPACT);
  }
} 