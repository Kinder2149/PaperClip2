# scripts/guardrails/pre-commit.ps1
# Exécute le guardrail UI avant commit
# Usage: powershell -ExecutionPolicy Bypass -File scripts/guardrails/pre-commit.ps1

Write-Host "[Guardrails] Vérification des imports UI..." -ForegroundColor Cyan
$dart = Get-Command dart -ErrorAction SilentlyContinue
if (-not $dart) {
  Write-Host "Dart SDK introuvable. Skipping guardrail (CI l'exécutera)." -ForegroundColor Yellow
  exit 0
}

& dart tools/guardrails/check_ui_imports.dart
if ($LASTEXITCODE -ne 0) {
  Write-Host "[Guardrails] Echec: corrigez les imports interdits avant de committer." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host "[Guardrails] OK" -ForegroundColor Green
exit 0
