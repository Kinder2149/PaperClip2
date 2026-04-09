# Script PowerShell pour exécuter tous les tests E2E Flutter
# Usage: .\integration_test\run_all_tests.ps1

Write-Host "[TEST] Running PaperClip2 Integration Tests..." -ForegroundColor Cyan

# Vérifier que Flutter est installé
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Flutter n'est pas installe ou pas dans le PATH" -ForegroundColor Red
    exit 1
}

# Démarrer l'émulateur Firebase (si configuré)
if ($env:USE_LOCAL_EMULATOR -eq "true") {
    Write-Host "[FIREBASE] Starting Firebase Emulators..." -ForegroundColor Yellow
    Push-Location functions
    Start-Process -NoNewWindow powershell -ArgumentList "firebase emulators:start --only functions,firestore,auth"
    Start-Sleep -Seconds 10
    Pop-Location
}

# Exécuter les tests
Write-Host "[TEST] Running integration tests..." -ForegroundColor Cyan

$tests = @(
    "integration_test/cloud_save_basic_test.dart",
    "integration_test/cloud_save_multi_device_test.dart",
    "integration_test/cloud_save_limit_test.dart"
)

$failedTests = @()

foreach ($test in $tests) {
    Write-Host "`n[RUN] Running $test..." -ForegroundColor Blue
    flutter test $test
    
    if ($LASTEXITCODE -ne 0) {
        $failedTests += $test
        Write-Host "[FAIL] Test failed: $test" -ForegroundColor Red
    } else {
        Write-Host "[PASS] Test passed: $test" -ForegroundColor Green
    }
}

# Résumé
Write-Host "`n[SUMMARY] Test Summary:" -ForegroundColor Cyan
Write-Host "Total tests: $($tests.Count)" -ForegroundColor White
Write-Host "Passed: $($tests.Count - $failedTests.Count)" -ForegroundColor Green
Write-Host "Failed: $($failedTests.Count)" -ForegroundColor Red

if ($failedTests.Count -gt 0) {
    Write-Host "`n[FAIL] Failed tests:" -ForegroundColor Red
    foreach ($test in $failedTests) {
        Write-Host "  - $test" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
    exit 0
}
