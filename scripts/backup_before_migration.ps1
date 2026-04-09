# Backup complet avant migration
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backup_migration_$timestamp"

Write-Host "🔄 BACKUP AVANT MIGRATION" -ForegroundColor Cyan
Write-Host "📁 Dossier: $backupDir" -ForegroundColor Yellow

# 1. Backup Git
Write-Host "`n1️⃣ Backup Git..." -ForegroundColor Green
git checkout -b "backup/pre-migration-$timestamp"
git add .
git commit -m "Backup: Before migration multi→single ($timestamp)"
git tag "backup-migration-$timestamp"

# 2. Backup code
Write-Host "`n2️⃣ Backup code..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $backupDir
Copy-Item -Path "lib" -Destination "$backupDir/lib" -Recurse
Copy-Item -Path "functions" -Destination "$backupDir/functions" -Recurse
Copy-Item -Path "pubspec.yaml" -Destination "$backupDir/"
Copy-Item -Path "package.json" -Destination "$backupDir/"

# 3. Backup données locales (si nécessaire)
Write-Host "`n3️⃣ Backup données locales..." -ForegroundColor Green
$localAppData = "$env:LOCALAPPDATA\PaperClip2"
if (Test-Path $localAppData) {
    Copy-Item -Path $localAppData -Destination "$backupDir/local_data" -Recurse
}

Write-Host "`n✅ BACKUP TERMINÉ: $backupDir" -ForegroundColor Green
Write-Host "📌 Tag Git: backup-migration-$timestamp" -ForegroundColor Yellow
