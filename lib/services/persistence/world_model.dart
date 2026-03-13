/// Modèle local minimal du Monde, aligné avec le contrat cloud.
///
/// Champs obligatoires:
/// - worldId: Identifiant technique (UUID v4) du monde. Sert de clé primaire locale et cloud.
/// - name: Nom affichable du monde (UI, métadonnée).
/// - createdAt: Date de création du monde (ISO, immuable).
/// - updatedAt: Date de dernière mise à jour (ISO, monotone non décroissante).
/// - gameVersion: Version applicative qui a produit le snapshot.
/// - snapshot: Payload opaque (JSON) du `GameSnapshot` sérialisé.
class World {
  /// Identifiant technique du monde (UUID v4), utilisé comme ID-first (`partieId`).
  final String worldId;
  /// Nom affichable du monde (pour l'UI et les listes locales/cloud).
  final String name;
  /// Date/heure de création du monde.
  final DateTime createdAt;
  /// Date/heure de dernière modification connue.
  final DateTime updatedAt;
  /// Version applicative qui a produit le snapshot.
  final String gameVersion;
  /// Snapshot opaque (JSON) associé au Monde au dernier enregistrement local.
  final Map<String, dynamic> snapshot;

  const World({
    required this.worldId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.gameVersion,
    required this.snapshot,
  });

  /// Sérialise le monde pour stockage/transport local.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'worldId': worldId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'gameVersion': gameVersion,
        'snapshot': snapshot,
      };

  /// Désérialise un monde depuis une Map JSON.
  factory World.fromJson(Map<String, dynamic> json) {
    return World(
      worldId: json['worldId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      gameVersion: json['gameVersion'] as String,
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map),
    );
  }
}
