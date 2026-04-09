# Script PowerShell pour exécuter les tests cloud automatisés
# Compte test: test.keamder@gmail.com

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTS AUTOMATISÉS - CLOUD SYNC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 PRÉREQUIS:" -ForegroundColor Yellow
Write-Host "   1. Compte test: test.keamder@gmail.com" -ForegroundColor White
Write-Host "   2. Backend déployé et accessible" -ForegroundColor White
Write-Host "   3. Fichier .env configuré" -ForegroundColor White
Write-Host ""

Write-Host "🚀 ÉTAPES D'EXÉCUTION:" -ForegroundColor Yellow
Write-Host ""

# Étape 1: Lancer l'application
Write-Host "ÉTAPE 1/3: Lancement de l'application..." -ForegroundColor Green
Write-Host "   Commande: flutter run -d chrome --web-port=50652" -ForegroundColor Gray
Write-Host ""
Write-Host "   ⚠️  ACTION REQUISE:" -ForegroundColor Red
Write-Host "   1. Attendez que l'app s'ouvre dans Chrome" -ForegroundColor White
Write-Host "   2. Connectez-vous avec: test.keamder@gmail.com" -ForegroundColor White
Write-Host "   3. Mot de passe: 6W@693SZiD01" -ForegroundColor White
Write-Host "   4. Attendez la synchronisation initiale" -ForegroundColor White
Write-Host "   5. Appuyez sur ENTRÉE pour continuer..." -ForegroundColor Yellow
Write-Host ""

# Lancer l'app en arrière-plan
$appProcess = Start-Process -FilePath "flutter" -ArgumentList "run", "-d", "chrome", "--web-port=50652" -PassThru -NoNewWindow

# Attendre confirmation utilisateur
Read-Host "   Appuyez sur ENTRÉE après vous être connecté"

Write-Host ""
Write-Host "ÉTAPE 2/3: Vérification de la connexion..." -ForegroundColor Green
Write-Host "   Les tests vont vérifier que vous êtes connecté" -ForegroundColor Gray
Write-Host ""

# Étape 2: Exécuter les tests
Write-Host "ÉTAPE 3/3: Exécution des tests automatisés..." -ForegroundColor Green
Write-Host ""

flutter test test/integration_test/cloud_sync_automated_test.dart --reporter=expanded

# Capturer le code de sortie
$testExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($testExitCode -eq 0) {
    Write-Host "✅ TOUS LES TESTS SONT PASSÉS" -ForegroundColor Green
} else {
    Write-Host "❌ CERTAINS TESTS ONT ÉCHOUÉ" -ForegroundColor Red
    Write-Host "   Code de sortie: $testExitCode" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup: Arrêter l'application
Write-Host "🧹 Nettoyage..." -ForegroundColor Yellow
if ($appProcess -and !$appProcess.HasExited) {
    Write-Host "   Arrêt de l'application Flutter..." -ForegroundColor Gray
    Stop-Process -Id $appProcess.Id -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "✅ Terminé" -ForegroundColor Green
Write-Host ""

# Retourner le code de sortie des tests
exit $testExitCode
