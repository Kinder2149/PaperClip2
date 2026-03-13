Param(
  [string]$EnvPath = ".env",
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Read-DotEnv([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw ".env introuvable à l'emplacement: $path"
  }
  $vars = @{}
  Get-Content -LiteralPath $path | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { return }
    if ($line.StartsWith('#')) { return }
    $idx = $line.IndexOf('=')
    if ($idx -lt 1) { return }
    $k = $line.Substring(0, $idx).Trim()
    $v = $line.Substring($idx + 1).Trim()
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Trim('"') }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Trim("'") }
    $vars[$k] = $v
  }
  return $vars
}

try {
  Write-Host "[check_env] Lecture de $EnvPath ..."
  $envVars = Read-DotEnv -path $EnvPath

  if (-not $envVars.ContainsKey('BACKEND_BASE_URL')) {
    throw "Variable manquante: BACKEND_BASE_URL"
  }
  $baseUrl = ($envVars['BACKEND_BASE_URL'] | ForEach-Object { $_.Trim() })
  if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    throw "BACKEND_BASE_URL est vide"
  }

  # Validation minimale de format (Cloud Functions us-central1)
  $regex = '^https://us-central1-[a-z0-9-]+\.cloudfunctions\.net/api/?$'
  if ($Strict.IsPresent -and (-not ($baseUrl -match $regex))) {
    throw "BACKEND_BASE_URL invalide pour Cloud Functions (attendu: https://us-central1-<project-id>.cloudfunctions.net/api)"
  }

  Write-Host "[check_env] OK: BACKEND_BASE_URL défini (format strict: $($Strict.IsPresent))" -ForegroundColor Green
  exit 0
}
catch {
  Write-Error "[check_env] ECHEC: $($_.Exception.Message)"
  exit 1
}
