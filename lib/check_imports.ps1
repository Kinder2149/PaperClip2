# Script de vérification et nettoyage des imports Dart

function Analyze-DartImports {
    param (
        [string]$ProjectRoot
    )

    # Fonction pour vérifier les imports
    function Test-ImportPath {
        param ([string]$Import)

        # Vérifier si l'import commence par package:paperclip2/
        if ($Import -notmatch "^import\s+'package:paperclip2/") {
            Write-Warning "Import invalide: $Import"
            return $false
        }

        # Vérifier si le fichier importé existe
        $importPath = $Import -replace "^import\s+'package:paperclip2/", $ProjectRoot
        $importPath = $importPath -replace "';"

        if (-not (Test-Path $importPath)) {
            Write-Warning "Fichier non trouvé: $importPath"
            return $false
        }

        return $true
    }

    # Récupérer tous les fichiers Dart
    $dartFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter *.dart

    $invalidImports = @()

    foreach ($file in $dartFiles) {
        $content = Get-Content $file.FullName
        $imports = $content | Where-Object { $_ -match "^import " }

        foreach ($import in $imports) {
            if (-not (Test-ImportPath -Import $import)) {
                $invalidImports += @{
                    File = $file.FullName
                    Import = $import
                }
            }
        }
    }

    # Rapport des imports invalides
    if ($invalidImports.Count -gt 0) {
        Write-Host "Imports invalides trouvés:" -ForegroundColor Yellow
        foreach ($inv in $invalidImports) {
            Write-Host "Fichier: $($inv.File)" -ForegroundColor Red
            Write-Host "Import: $($inv.Import)" -ForegroundColor Red
        }
        return $false
    }

    Write-Host "Tous les imports sont valides." -ForegroundColor Green
    return $true
}

# Utilisation du script
$projectRoot = "D:\Coding\AppMobile\paperclip2\lib"
Analyze-DartImports -ProjectRoot $projectRoot