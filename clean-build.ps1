# Nettoyer en profondeur
Remove-Item -Path "android/app/build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".flutter-plugins" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android/.gradle" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Nettoyage des dossiers terminé" -ForegroundColor Green

# Nettoyer Flutter et récupérer les dépendances
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du flutter clean" -ForegroundColor Red
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du flutter pub get" -ForegroundColor Red
    exit 1
}

# Construire avec Gradle
Push-Location android
Write-Host "Configuration de Gradle..." -ForegroundColor Yellow

# Utiliser directement gradlew sans les options problématiques
.\gradlew clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du gradlew clean" -ForegroundColor Red
    Pop-Location
    exit 1
}

.\gradlew assembleRelease
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du gradlew assembleRelease" -ForegroundColor Red
    Pop-Location
    exit 1
}

.\gradlew bundleRelease
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du gradlew bundleRelease" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Revenir au dossier principal
Pop-Location

# Construire le bundle avec détails
Write-Host "Construction du bundle Flutter..." -ForegroundColor Yellow
flutter build appbundle --release

# Vérifier tous les chemins possibles pour le fichier .aab
$possiblePaths = @(
    "build/app/outputs/bundle/release/app-release.aab",
    "android/app/build/outputs/bundle/release/app-release.aab"
)

$bundleFound = $false
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        Write-Host "Bundle trouvé à : $path" -ForegroundColor Green
        $bundleFound = $true
        Copy-Item $path -Destination "./app-release.aab" -Force
        Write-Host "Bundle copié à la racine du projet" -ForegroundColor Green
        break
    }
}

if (-not $bundleFound) {
    Write-Host "Erreur : Bundle non trouvé dans les chemins attendus" -ForegroundColor Red
    exit 1
}