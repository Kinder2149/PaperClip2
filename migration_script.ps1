# Script de migration de Firebase vers l'API personnalisée
# Ce script remplace les anciens services Firebase par les nouveaux services API

# Fonction pour remplacer un fichier
function Replace-File {
    param (
        [string]$OldFile,
        [string]$NewFile
    )
    
    if (Test-Path $OldFile) {
        # Sauvegarder l'ancien fichier
        $backupFile = "$OldFile.bak"
        Copy-Item -Path $OldFile -Destination $backupFile -Force
        
        # Remplacer par le nouveau fichier
        Copy-Item -Path $NewFile -Destination $OldFile -Force
        
        # Supprimer le fichier temporaire
        if (Test-Path $NewFile) {
            Remove-Item -Path $NewFile -Force
        }
        
        Write-Host "Fichier remplacé: $OldFile (sauvegarde: $backupFile)" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le fichier $OldFile n'existe pas" -ForegroundColor Red
    }
}

# Chemin de base
$basePath = "d:\Coding\AppMobile\paperclip2"

# 1. Remplacer UserManager
Write-Host "Remplacement de UserManager..." -ForegroundColor Yellow
Replace-File "$basePath\lib\services\user\user_manager.dart" "$basePath\lib\services\user\user_manager_new.dart"

# 2. Remplacer FriendsService
Write-Host "Remplacement de FriendsService..." -ForegroundColor Yellow
Replace-File "$basePath\lib\services\social\friends_service.dart" "$basePath\lib\services\social\friends_service_new.dart"

# 3. Remplacer UserStatsService
Write-Host "Remplacement de UserStatsService..." -ForegroundColor Yellow
Replace-File "$basePath\lib\services\social\user_stats_service.dart" "$basePath\lib\services\social\user_stats_service_new.dart"

# 4. Remplacer pubspec.yaml
Write-Host "Mise à jour du fichier pubspec.yaml..." -ForegroundColor Yellow
Replace-File "$basePath\pubspec.yaml" "$basePath\pubspec.yaml.new"

# 5. Supprimer les fichiers de configuration Firebase
Write-Host "Suppression des fichiers de configuration Firebase..." -ForegroundColor Yellow

$firebaseFiles = @(
    "$basePath\android\app\google-services.json",
    "$basePath\ios\Runner\GoogleService-Info.plist",
    "$basePath\ios\firebase_app_id_file.json"
)

foreach ($file in $firebaseFiles) {
    if (Test-Path $file) {
        # Sauvegarder le fichier
        $backupFile = "$file.bak"
        Copy-Item -Path $file -Destination $backupFile -Force
        
        # Supprimer le fichier
        Remove-Item -Path $file -Force
        
        Write-Host "Fichier supprimé: $file (sauvegarde: $backupFile)" -ForegroundColor Green
    } else {
        Write-Host "Fichier non trouvé: $file" -ForegroundColor Yellow
    }
}

# 6. Exécuter flutter pub get pour mettre à jour les dépendances
Write-Host "Mise à jour des dépendances..." -ForegroundColor Yellow
Set-Location -Path $basePath
flutter pub get

Write-Host "Migration terminée avec succès!" -ForegroundColor Green
Write-Host "Les fichiers originaux ont été sauvegardés avec l'extension .bak" -ForegroundColor Cyan
Write-Host "N'oubliez pas de configurer le fichier .env avec l'URL de votre backend FastAPI" -ForegroundColor Yellow
