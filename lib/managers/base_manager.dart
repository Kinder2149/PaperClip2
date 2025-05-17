// lib/core/base_manager.dart
import 'package:flutter/foundation.dart';

/// Interface commune pour tous les managers du jeu
abstract class BaseManager {
  /// Initialise le manager avec ses dépendances
  Future<void> initialize();

  /// Démarre le fonctionnement du manager (timers, etc.)
  void start();

  /// Pause les opérations actives du manager
  void pause();

  /// Reprend les opérations après une pause
  void resume();

  /// Libère les ressources du manager
  void dispose();

  /// Convertit l'état du manager en Map pour la sauvegarde
  Map<String, dynamic> toJson();

  /// Charge l'état du manager depuis une Map
  void fromJson(Map<String, dynamic> json);

  /// Vérifie si le manager est initialisé
  bool get isInitialized;
}