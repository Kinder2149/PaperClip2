param(
  [string]$ProjectId = "paperclip-98294",
  [string]$ApiKey = "AIzaSyC2OA70p2-RhwjkblhXva9yvNm81aKiqSY"
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$API = "https://us-central1-$ProjectId.cloudfunctions.net/api"
$AuthBase = 'https://identitytoolkit.googleapis.com/v1'
Write-Host "API Base: $API"

function New-TestUserReturnIdToken([string]$email) {
  $uri = "$AuthBase/accounts:signUp?key=$ApiKey"
  $body = @{ email = $email; password = 'Pc2!Test-PROD'; returnSecureToken = $true } | ConvertTo-Json
  $resp = Invoke-RestMethod -Method Post -Uri $uri -ContentType 'application/json' -Body $body
  return $resp.idToken
}

function Put-Save([string]$token, [string]$partieId, [hashtable]$core) {
  $headers = @{ Authorization = "Bearer $token"; 'Content-Type'='application/json' }
  $payload = @{ snapshot = @{ metadata = @{ partieId = $partieId }; core = $core; stats = @{} } } | ConvertTo-Json -Depth 10
  return Invoke-WebRequest -Method Put -Uri ("$API/saves/$partieId") -Headers $headers -Body $payload -UseBasicParsing
}

function Get-Latest([string]$token, [string]$partieId) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-WebRequest -Method Get -Uri ("$API/saves/$partieId/latest") -Headers $headers -UseBasicParsing
}

function Delete-Save([string]$token, [string]$partieId) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-WebRequest -Method Delete -Uri ("$API/saves/$partieId") -Headers $headers -UseBasicParsing
}

function Get-List([string]$token) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-WebRequest -Method Get -Uri ("$API/saves?page=1`&limit=50") -Headers $headers -UseBasicParsing
}

# Variantes JSON (Invoke-RestMethod) et Versions APIs
function Get-ListJson([string]$token) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-RestMethod -Method Get -Uri ("$API/saves?page=1`&limit=50") -Headers $headers
}

function Get-Versions([string]$token, [string]$partieId) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-RestMethod -Method Get -Uri ("$API/saves/$partieId/versions") -Headers $headers
}

function Get-VersionSnapshot([string]$token, [string]$partieId, [int]$version) {
  $headers = @{ Authorization = "Bearer $token" }
  return Invoke-RestMethod -Method Get -Uri ("$API/saves/$partieId/versions/$version") -Headers $headers
}

# --- Création utilisateurs A/B ---
$ts = Get-Date -Format 'yyyyMMddHHmmss'
$emailA = "userA+$ts@example.com"
$emailB = "userB+$ts@example.com"
$idTokenA = New-TestUserReturnIdToken -email $emailA
$idTokenB = New-TestUserReturnIdToken -email $emailB
Write-Host "UserA: $emailA"
Write-Host "UserB: $emailB"

# --- Scénario A: 2 mondes, versions, restore, suppression ---
$p1 = [guid]::NewGuid().ToString()
$p2 = [guid]::NewGuid().ToString()

$r_put1 = Put-Save -token $idTokenA -partieId $p1 -core @{ k = 'v1' }
$r_put2 = Put-Save -token $idTokenA -partieId $p1 -core @{ k = 'v2' }
$r_put3 = Put-Save -token $idTokenA -partieId $p2 -core @{ k = 'v1' }

$r_l1 = Get-Latest -token $idTokenA -partieId $p1
$r_l2 = Get-Latest -token $idTokenA -partieId $p2

# Restore P1 (repousser v1)
$r_restore = Put-Save -token $idTokenA -partieId $p1 -core @{ k = 'v1' }

# Delete P2 puis liste
$r_del = Delete-Save -token $idTokenA -partieId $p2
$r_list = Get-List -token $idTokenA

# --- Amorçage côté B: créer une sauvegarde pour disposer d'un chosenB ---
$pB_seed = [guid]::NewGuid().ToString()
Put-Save -token $idTokenB -partieId $pB_seed -core @{ seed = 'b1' } | Out-Null

# --- Scénario croisé A/B ---
# 1) Récupérer l'index A et choisir la dernière partie
$listAJson = Get-ListJson -token $idTokenA
$chosenA = ($listAJson.items | Select-Object -Last 1).partie_id
# 2) Récupérer l'index B et choisir la dernière partie
$listBJson = Get-ListJson -token $idTokenB
$chosenB = ($listBJson.items | Select-Object -Last 1).partie_id

# 3) Vérifier versions et snapshots v1/latest pour A
$versAJson = $null; $v1AJson = $null; $latAJson = $null
if ($chosenA) {
  $versAJson = Get-Versions -token $idTokenA -partieId $chosenA
  $v1AJson = Get-VersionSnapshot -token $idTokenA -partieId $chosenA -version 1
  $latAJson = Invoke-RestMethod -Method Get -Uri ("$API/saves/$chosenA/latest") -Headers @{ Authorization = "Bearer $idTokenA" }
}

# 4) Vérifier versions et snapshots v1/latest pour B
$versBJson = $null; $v1BJson = $null; $latBJson = $null
if ($chosenB) {
  $versBJson = Get-Versions -token $idTokenB -partieId $chosenB
  $v1BJson = Get-VersionSnapshot -token $idTokenB -partieId $chosenB -version 1
  $latBJson = Invoke-RestMethod -Method Get -Uri ("$API/saves/$chosenB/latest") -Headers @{ Authorization = "Bearer $idTokenB" }
}

# 5) Lectures croisées attendues 404
$isoAbyB = ''
if ($chosenA) {
  try {
    $r_ab = Get-Latest -token $idTokenB -partieId $chosenA
    $isoAbyB = $r_ab.StatusCode
  } catch {
    if ($_.Exception.Response) { $isoAbyB = $_.Exception.Response.StatusCode.Value__ } else { $isoAbyB = 'error' }
  }
}
$isoBbyA = ''
if ($chosenB) {
  try {
    $r_ba = Get-Latest -token $idTokenA -partieId $chosenB
    $isoBbyA = $r_ba.StatusCode
  } catch {
    if ($_.Exception.Response) { $isoBbyA = $_.Exception.Response.StatusCode.Value__ } else { $isoBbyA = 'error' }
  }
}

# --- Limites ---
# Snapshot incomplet
$badId = [guid]::NewGuid().ToString()
$badPayload = @{ snapshot = @{ metadata = @{}; core=@{}; stats=@{} } } | ConvertTo-Json -Depth 10
$bad_status = ''
try {
  $headersA = @{ Authorization = "Bearer $idTokenA"; 'Content-Type'='application/json' }
  $r_bad = Invoke-WebRequest -Method Put -Uri "$API/saves/$badId" -Headers $headersA -Body $badPayload -UseBasicParsing -ErrorAction Stop
  $bad_status = $r_bad.StatusCode
} catch {
  if ($_.Exception.Response) { $bad_status = $_.Exception.Response.StatusCode.Value__ } else { $bad_status = 'error' }
}

# Partie inexistante
$noneId = [guid]::NewGuid().ToString()
$none_status = ''
try {
  $r_none = Get-Latest -token $idTokenA -partieId $noneId
  $none_status = $r_none.StatusCode
} catch {
  if ($_.Exception.Response) { $none_status = $_.Exception.Response.StatusCode.Value__ } else { $none_status = 'error' }
}

# --- Résumé ---
Write-Host "=== Résultats Scénario A ==="
Write-Host ("PUT P1 v1: {0}" -f $r_put1.StatusCode)
Write-Host ("PUT P1 v2: {0}" -f $r_put2.StatusCode)
Write-Host ("PUT P2 v1: {0}" -f $r_put3.StatusCode)
Write-Host ("GET latest P1: {0}" -f $r_l1.StatusCode)
Write-Host ("GET latest P2: {0}" -f $r_l2.StatusCode)
Write-Host ("RESTORE P1: {0}" -f $r_restore.StatusCode)
Write-Host ("DELETE P2: {0}" -f $r_del.StatusCode)
Write-Host ("LIST after: {0}" -f $r_list.StatusCode)
Write-Host $r_list.Content
Write-Host "=== Index/Versions (croisé) ==="
Write-Host ("chosenA: {0}" -f $chosenA)
if ($versAJson) { Write-Host ("VERS(A): {0}" -f ($versAJson.items | ForEach-Object { $_.version } | Sort-Object | ForEach-Object { $_ })) }
if ($v1AJson)   { Write-Host ("v1(A).partieId: {0}" -f $v1AJson.snapshot.metadata.partieId) }
if ($latAJson)  { Write-Host ("latest(A).partieId: {0}" -f $latAJson.snapshot.metadata.partieId) }
Write-Host ("chosenB: {0}" -f $chosenB)
if ($versBJson) { Write-Host ("VERS(B): {0}" -f ($versBJson.items | ForEach-Object { $_.version } | Sort-Object | ForEach-Object { $_ })) }
if ($v1BJson)   { Write-Host ("v1(B).partieId: {0}" -f $v1BJson.snapshot.metadata.partieId) }
if ($latBJson)  { Write-Host ("latest(B).partieId: {0}" -f $latBJson.snapshot.metadata.partieId) }

Write-Host "=== Isolation croisée ==="
Write-Host ("GET(A by B)/latest: {0}" -f $isoAbyB)
Write-Host ("GET(B by A)/latest: {0}" -f $isoBbyA)
Write-Host "=== Limites ==="
Write-Host ("Incomplet snapshot: {0}" -f $bad_status)
Write-Host ("Partie inexistante: {0}" -f $none_status)
Write-Host ("P1: {0}" -f $p1)
Write-Host ("P2: {0}" -f $p2)
