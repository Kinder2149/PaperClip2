# Créer ce script dans clean-build.ps1
# Nettoyer en profondeur
Remove-Item -Path "android/app/build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".flutter-plugins" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android/.gradle" -Recurse -Force -ErrorAction SilentlyContinue

# Nettoyer Flutter et récupérer les dépendances
flutter clean
flutter pub get

# Construire avec Gradle (avec plus de détails)
Set-Location android
.\gradlew clean --info
.\gradlew assembleRelease --stacktrace
.\gradlew bundleRelease --stacktrace

# Revenir au dossier principal
Set-Location ..

# Construire le bundle avec détails
flutter build appbundle --release --verbose

# Vérifier tous les chemins possibles pour le fichier .aab
$possiblePaths = @(
    "build/app/outputs/bundle/release/app-release.aab",
    "android/app/build/outputs/bundle/release/app-release.aab"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        Write-Host "Bundle trouvé à : $path"
        Exit 0
    }
}

Write-Host "Erreur : Bundle non trouvé dans les chemins attendus"
Exit 1