# Script de lancement des tests d'intégration Auth + Cloud Save
# Usage: .\test\integration_test\run_tests.ps1

Write-Host "🧪 Lancement des tests d'intégration Auth + Cloud Save" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Flutter est installé
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Erreur: Flutter n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    exit 1
}

# Vérifier que le fichier .env existe
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  Avertissement: Fichier .env manquant" -ForegroundColor Yellow
    Write-Host "   Création du fichier .env avec valeurs par défaut..." -ForegroundColor Yellow
    
    $envContent = @"
APP_ENV=development
FUNCTIONS_API_BASE=https://api-g3tpwosnaq-uc.a.run.app
FEATURE_CLOUD_ENTERPRISE=true
DEBUG_MODE=true
"@
    Set-Content -Path ".env" -Value $envContent
    Write-Host "✅ Fichier .env créé" -ForegroundColor Green
}

# Afficher les options
Write-Host "Plateformes disponibles:" -ForegroundColor White
Write-Host "  1. Chrome (Web) - Recommandé" -ForegroundColor Green
Write-Host "  2. Android (Émulateur/Device)" -ForegroundColor Yellow
Write-Host "  3. Tous les tests unitaires" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Choisir une option (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🌐 Lancement des tests sur Chrome..." -ForegroundColor Cyan
        Write-Host ""
        
        # Vérifier que Chrome est disponible
        $chromeDevices = flutter devices | Select-String "Chrome"
        if (-not $chromeDevices) {
            Write-Host "❌ Chrome n'est pas disponible" -ForegroundColor Red
            exit 1
        }
        
        # Lancer les tests d'intégration sur Chrome
        flutter test integration_test/auth_cloud_flow_test.dart -d chrome --verbose
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Tests terminés avec succès!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Certains tests ont échoué" -ForegroundColor Red
            exit 1
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "📱 Lancement des tests sur Android..." -ForegroundColor Cyan
        Write-Host ""
        
        # Lister les devices Android
        $androidDevices = flutter devices | Select-String "android"
        if (-not $androidDevices) {
            Write-Host "❌ Aucun device Android disponible" -ForegroundColor Red
            Write-Host "   Lancez un émulateur ou connectez un device" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Devices Android disponibles:" -ForegroundColor White
        flutter devices | Select-String "android"
        Write-Host ""
        
        $deviceId = Read-Host "Entrer l'ID du device (ou laisser vide pour le premier)"
        
        if ($deviceId) {
            flutter test integration_test/auth_cloud_flow_test.dart -d $deviceId --verbose
        } else {
            flutter test integration_test/auth_cloud_flow_test.dart --verbose
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Tests terminés avec succès!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Certains tests ont échoué" -ForegroundColor Red
            exit 1
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "🧪 Lancement de tous les tests unitaires..." -ForegroundColor Cyan
        Write-Host ""
        
        flutter test test/unit/ --verbose
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Tous les tests unitaires ont réussi!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Certains tests unitaires ont échoué" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host "❌ Option invalide" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📊 Résumé des tests disponibles:" -ForegroundColor Cyan
Write-Host "  - TEST 1-3   : Initialisation Firebase & CloudPort" -ForegroundColor White
Write-Host "  - TEST 4-7   : Création entreprise & Snapshot v3" -ForegroundColor White
Write-Host "  - TEST 8-15  : Restauration & Validation données" -ForegroundColor White
Write-Host "  - TEST 16-18 : CloudPort Manager" -ForegroundColor White
Write-Host "  - TEST 19-22 : Snapshot avancés" -ForegroundColor White
Write-Host ""
Write-Host "Total: 22 tests automatisés" -ForegroundColor Green
