/// Port de readiness pour la synchronisation.
/// Permet de découpler l'orchestrateur des détails d'identité / réseau / consentement.
abstract class SyncReadinessPort {
  /// true si l'utilisateur est connecté ET a activé la synchronisation.
  Future<bool> isSyncAllowed();

  /// true si la connectivité réseau est suffisante pour tenter un envoi.
  Future<bool> hasNetwork();
}
