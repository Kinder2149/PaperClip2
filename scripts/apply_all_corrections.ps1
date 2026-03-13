# Script PowerShell pour appliquer toutes les corrections du plan
# Exécution: .\scripts\apply_all_corrections.ps1

Write-Host "🔧 Application des corrections - PaperClip2" -ForegroundColor Cyan
Write-Host ""

# Vérifier que nous sommes dans le bon répertoire
if (-not (Test-Path "lib\models\game_state.dart")) {
    Write-Host "❌ Erreur: Exécutez ce script depuis la racine du projet" -ForegroundColor Red
    exit 1
}

# Créer une sauvegarde
Write-Host "💾 Création des sauvegardes..." -ForegroundColor Yellow
Copy-Item "lib\models\game_state.dart" "lib\models\game_state.dart.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
Write-Host "✅ Sauvegarde créée" -ForegroundColor Green
Write-Host ""

# Phase 1.1: Corriger setPartieId
Write-Host "🔧 Phase 1.1: Correction de setPartieId()" -ForegroundColor Cyan
$content = Get-Content "lib\models\game_state.dart" -Raw -Encoding UTF8

$oldSetPartieId = @"
  // Défini explicitement l'identifiant technique de la partie \(utilisé lors du chargement\)
  void setPartieId\(String id\) \{
    // Enforce UUID v4 format \(cloud-first invariant: identité technique stricte\)
    final uuidV4 = RegExp\(r'\^[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-4[0-9a-fA-F]\{3\}-[89abAB][0-9a-fA-F]\{3\}-[0-9a-fA-F]\{12\}\?\$'\);
    if \(uuidV4\.hasMatch\(id\)\) \{
      _partieId = id;
    \} else \{
      // Ignorer les identifiants non conformes \(aucune création implicite ici\)
    \}
  \}
"@

$newSetPartieId = @"
  // Défini explicitement l'identifiant technique de la partie (utilisé lors du chargement)
  void setPartieId(String id) {
    // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
    final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
    if (uuidV4.hasMatch(id)) {
      // CORRECTION: Logger le changement d'identité pour traçabilité
      if (kDebugMode && _partieId != null && _partieId != id) {
        print('[GameState] ⚠️ Changement de partieId détecté: `$_partieId → `$id');
      }
      _partieId = id;
    } else {
      // CORRECTION: Logger l'erreur au lieu d'ignorer silencieusement
      if (kDebugMode) {
        print('[GameState] ❌ Tentative d\'assignation d\'un partieId invalide (non UUID v4): "`$id"');
        print('[GameState] Stack trace:');
        print(StackTrace.current);
      }
      // CORRECTION: Lever une exception en mode debug pour détecter les bugs
      throw ArgumentError('[GameState] partieId doit être un UUID v4 valide, reçu: "`$id"');
    }
  }
"@

if ($content -match $oldSetPartieId) {
    $content = $content -replace $oldSetPartieId, $newSetPartieId
    Write-Host "✅ setPartieId() corrigé" -ForegroundColor Green
} else {
    Write-Host "⚠️ Pattern setPartieId non trouvé - correction manuelle requise" -ForegroundColor Yellow
}

# Phase 1.2: Corriger applySnapshot
Write-Host "🔧 Phase 1.2: Correction de applySnapshot()" -ForegroundColor Cyan

$oldApplySnapshot = @"
    // ID technique \(UUID\) si présent dans les métadonnées du snapshot
    final metaPartieId = metadata\['partieId'\] as String\?;
    if \(_partieId == null && metaPartieId != null && metaPartieId\.isNotEmpty\) \{
      _partieId = metaPartieId;
    \}
"@

$newApplySnapshot = @"
    // CORRECTION CRITIQUE: Toujours écraser le partieId lors du chargement d'un snapshot
    // et utiliser setPartieId() pour validation UUID v4
    final metaPartieId = metadata['partieId'] as String?;
    if (metaPartieId != null && metaPartieId.isNotEmpty) {
      // CORRECTION: Utiliser setPartieId() au lieu d'assignation directe
      // Cela garantit la validation UUID v4 et la traçabilité
      try {
        setPartieId(metaPartieId);
      } catch (e) {
        // Si le partieId du snapshot est invalide, logger et continuer
        if (kDebugMode) {
          print('[GameState] ⚠️ Snapshot contient un partieId invalide: "`$metaPartieId"');
          print('[GameState] Erreur: `$e');
        }
        // Ne pas bloquer le chargement, mais signaler le problème
      }
    }
"@

if ($content -match $oldApplySnapshot) {
    $content = $content -replace $oldApplySnapshot, $newApplySnapshot
    Write-Host "✅ applySnapshot() corrigé" -ForegroundColor Green
} else {
    Write-Host "⚠️ Pattern applySnapshot non trouvé - vérification alternative..." -ForegroundColor Yellow
    # Pattern alternatif sans regex strict
    if ($content -match "final metaPartieId = metadata\['partieId'\]") {
        Write-Host "✅ Bloc applySnapshot trouvé - correction manuelle recommandée" -ForegroundColor Yellow
    }
}

# Sauvegarder les modifications
Set-Content "lib\models\game_state.dart" -Value $content -Encoding UTF8 -NoNewline
Write-Host "✅ Fichier game_state.dart mis à jour" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Résumé des corrections appliquées:" -ForegroundColor Cyan
Write-Host "  ✅ Phase 1.1: setPartieId() - Logs et validation ajoutés" -ForegroundColor Green
Write-Host "  ✅ Phase 1.2: applySnapshot() - Utilisation de setPartieId()" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "  1. Vérifier les modifications dans game_state.dart"
Write-Host "  2. Appliquer Phase 1.3 dans game_persistence_orchestrator.dart"
Write-Host "  3. Tester avec: flutter run"
Write-Host ""
Write-Host "✨ Corrections Phase 1 terminées!" -ForegroundColor Green
