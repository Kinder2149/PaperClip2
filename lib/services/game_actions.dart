import '../models/game_state.dart';

class GameActions {
  final GameState _gameState;

  GameActions({required GameState gameState}) : _gameState = gameState;

  void producePaperclip() {
    _gameState.producePaperclip();
  }

  void buyAutoclipper() {
    _gameState.buyAutoclipper();
  }

  void setAutoSellEnabled(bool value) {
    _gameState.setAutoSellEnabled(value);
  }

  bool purchaseMetal() {
    return _gameState.purchaseMetal();
  }

  void setSellPrice(double value) {
    _gameState.setSellPrice(value);
  }

  bool purchaseUpgrade(String upgradeId) {
    return _gameState.purchaseUpgrade(upgradeId);
  }

  void togglePause() {
    _gameState.togglePause();
  }
}
