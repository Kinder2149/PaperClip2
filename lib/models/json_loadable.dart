// lib/models/json_loadable.dart
// Interface commune pour la désérialisation des objets depuis JSON

/// Interface commune pour le chargement des données depuis JSON
abstract class JsonLoadable {
  /// Charge les données de l'objet depuis un Map JSON
  /// 
  /// Cette méthode standard doit être implémentée par toutes les classes
  /// qui peuvent être chargées depuis une sauvegarde JSON
  void fromJson(Map<String, dynamic> json);
}
