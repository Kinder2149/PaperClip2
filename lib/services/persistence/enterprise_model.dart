/// Modèle local minimal de l'Entreprise, aligné avec le contrat cloud.
///
/// Champs obligatoires:
/// - enterpriseId: Identifiant technique (UUID v4) de l'entreprise. Sert de clé primaire locale et cloud.
/// - name: Nom affichable de l'entreprise (UI, métadonnée).
/// - createdAt: Date de création de l'entreprise (ISO, immuable).
/// - updatedAt: Date de dernière mise à jour (ISO, monotone non décroissante).
/// - gameVersion: Version applicative qui a produit le snapshot.
/// - snapshot: Payload opaque (JSON) du `GameSnapshot` sérialisé.
class Enterprise {
  /// Identifiant technique de l'entreprise (UUID v4), utilisé comme ID-first.
  final String enterpriseId;
  /// Nom affichable de l'entreprise (pour l'UI et les listes locales/cloud).
  final String name;
  /// Date/heure de création de l'entreprise.
  final DateTime createdAt;
  /// Date/heure de dernière modification connue.
  final DateTime updatedAt;
  /// Version applicative qui a produit le snapshot.
  final String gameVersion;
  /// Snapshot opaque (JSON) associé à l'Entreprise au dernier enregistrement local.
  final Map<String, dynamic> snapshot;

  const Enterprise({
    required this.enterpriseId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.gameVersion,
    required this.snapshot,
  });

  /// Sérialise l'entreprise pour stockage/transport local.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'enterpriseId': enterpriseId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'gameVersion': gameVersion,
        'snapshot': snapshot,
      };

  /// Désérialise une entreprise depuis une Map JSON.
  factory Enterprise.fromJson(Map<String, dynamic> json) {
    return Enterprise(
      enterpriseId: json['enterpriseId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      gameVersion: json['gameVersion'] as String,
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map),
    );
  }
}
