# Script de mise à jour des imports pour le projet Flutter/Dart

function Update-Imports {
    param (
        [string]$ProjectRoot
    )

    # Fonction pour convertir un chemin de fichier en import Dart
    function Convert-PathToImport {
        param ([string]$FilePath, [string]$ProjectRoot)

        $relativePath = $FilePath.Replace($ProjectRoot, '').Replace('\', '/').TrimStart('/')
        $importPath = $relativePath -replace '\.dart$', ''
        return "import 'package:paperclip2/$importPath.dart';"
    }

    # Récupérer tous les fichiers Dart du projet
    $dartFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter *.dart

    foreach ($file in $dartFiles) {
        $content = Get-Content $file.FullName -Raw
        $updatedContent = $content

        # Liste des bases de recherche
        $importBases = @(
            'core',
            'data',
            'domain',
            'presentation'
        )

        # Rechercher et remplacer les imports
        foreach ($base in $importBases) {
            $pattern = "import '(\.{1,2}/$base/[^']*)';"
            $matches = [regex]::Matches($content, $pattern)

            foreach ($match in $matches) {
                $oldImport = $match.Value
                $newImport = Convert-PathToImport -FilePath $file.FullName.Replace($match.Groups[1].Value, '') -ProjectRoot $ProjectRoot
                $updatedContent = $updatedContent -replace [regex]::Escape($oldImport), $newImport
            }
        }

        # Nettoyer les imports
        $importLines = $updatedContent -split '\r?\n' | Where-Object { $_ -match '^import ' }
        $uniqueImports = $importLines | Sort-Object -Unique

        $nonImportLines = $updatedContent -split '\r?\n' | Where-Object { $_ -notmatch '^import ' }

        $cleanedContent = ($uniqueImports -join "`n") + "`n`n" + ($nonImportLines -join "`n")

        # Écrire le contenu mis à jour
        $cleanedContent | Set-Content $file.FullName -Encoding UTF8
    }
}

# Utilisation du script
$projectRoot = "D:\Coding\AppMobile\paperclip2\lib"
Update-Imports -ProjectRoot $projectRoot

Write-Host "Mise à jour des imports terminée."