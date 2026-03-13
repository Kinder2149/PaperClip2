# Script de diagnostic pour vérifier l'état de synchronisation cloud
# Usage: .\scripts\diagnostic_cloud_state.ps1

Write-Host "=== Diagnostic Cloud State PaperClip2 ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier si l'app est en cours d'exécution
Write-Host "[1/5] Vérification processus Flutter..." -ForegroundColor Yellow
$flutterProcess = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
if ($flutterProcess) {
    Write-Host "✓ Flutter en cours d'exécution (PID: $($flutterProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter non détecté - Lancez 'flutter run' d'abord" -ForegroundColor Red
    exit 1
}

# 2. Rechercher les logs pertinents
Write-Host ""
Write-Host "[2/5] Analyse des logs Firebase Auth..." -ForegroundColor Yellow

# Filtrer les logs Firebase Auth
$authLogs = adb logcat -d | Select-String "FirebaseAuth|D/FirebaseAuth"
if ($authLogs) {
    Write-Host "✓ Logs Firebase Auth trouvés:" -ForegroundColor Green
    $authLogs | Select-Object -Last 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "✗ Aucun log Firebase Auth trouvé" -ForegroundColor Red
}

# 3. Vérifier les logs de synchronisation cloud
Write-Host ""
Write-Host "[3/5] Recherche logs synchronisation cloud..." -ForegroundColor Yellow

$syncLogs = adb logcat -d | Select-String "\[AUTH\]|\[PLAYER-CONNECTED\]|syncAllWorldsFromCloud|cloud_enabled"
if ($syncLogs) {
    Write-Host "✓ Logs synchronisation trouvés:" -ForegroundColor Green
    $syncLogs | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "⚠ Aucun log de synchronisation cloud - PROBLÈME DÉTECTÉ" -ForegroundColor Red
    Write-Host "  → La synchronisation ne s'est jamais déclenchée" -ForegroundColor Red
}

# 4. Vérifier les logs d'échec de chargement
Write-Host ""
Write-Host "[4/5] Vérification échecs de chargement..." -ForegroundColor Yellow

$failedLoads = adb logcat -d | Select-String "WORLD-SWITCH.*failed"
if ($failedLoads) {
    Write-Host "⚠ Échecs de chargement détectés:" -ForegroundColor Red
    $failedLoads | Select-Object -Last 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "✓ Aucun échec de chargement détecté" -ForegroundColor Green
}

# 5. Vérifier les logs CloudPort
Write-Host ""
Write-Host "[5/5] Vérification activation CloudPort..." -ForegroundColor Yellow

$cloudPortLogs = adb logcat -d | Select-String "CloudPort|cloud_port"
if ($cloudPortLogs) {
    Write-Host "✓ Logs CloudPort trouvés:" -ForegroundColor Green
    $cloudPortLogs | Select-Object -Last 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "⚠ Aucun log CloudPort - Vérifier activation" -ForegroundColor Red
}

# Résumé et recommandations
Write-Host ""
Write-Host "=== RÉSUMÉ ===" -ForegroundColor Cyan

$hasAuth = $authLogs -ne $null
$hasSync = $syncLogs -ne $null
$hasFails = $failedLoads -ne $null

if ($hasAuth -and $hasSync -and -not $hasFails) {
    Write-Host "✓ Système cloud fonctionnel" -ForegroundColor Green
} elseif ($hasAuth -and -not $hasSync) {
    Write-Host "✗ PROBLÈME : Utilisateur connecté mais sync cloud non déclenchée" -ForegroundColor Red
    Write-Host ""
    Write-Host "CAUSE PROBABLE : cloud_enabled=false" -ForegroundColor Yellow
    Write-Host "SOLUTION : Activer le cloud dans les paramètres OU relancer l'app après la correction" -ForegroundColor Yellow
} elseif ($hasFails) {
    Write-Host "✗ PROBLÈME : Mondes visibles mais non chargeables" -ForegroundColor Red
    Write-Host ""
    Write-Host "CAUSE : Données cloud non synchronisées localement" -ForegroundColor Yellow
    Write-Host "SOLUTION : Forcer synchronisation via pull-to-refresh" -ForegroundColor Yellow
} else {
    Write-Host "⚠ État indéterminé - Vérifier manuellement les logs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pour plus de détails, consultez les logs complets :" -ForegroundColor Cyan
Write-Host "  adb logcat -d | Select-String 'flutter|FirebaseAuth|CloudPort'" -ForegroundColor Gray
