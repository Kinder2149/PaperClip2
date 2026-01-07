param(
  [string]$ProjectId = "paperclip-98294",
  [string]$ApiKey = "AIzaSyC2OA70p2-RhwjkblhXva9yvNm81aKiqSY"
)

$ErrorActionPreference = 'Stop'

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

# --- Isolation: B ne lit pas A ---
$iso_status = ''
try {
  $r_b = Get-Latest -token $idTokenB -partieId $p1
  $iso_status = $r_b.StatusCode
} catch {
  if ($_.Exception.Response) { $iso_status = $_.Exception.Response.StatusCode.Value__ } else { $iso_status = 'error' }
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
Write-Host "=== Isolation (B sur P1/latest): $iso_status ==="
Write-Host "=== Limites ==="
Write-Host ("Incomplet snapshot: {0}" -f $bad_status)
Write-Host ("Partie inexistante: {0}" -f $none_status)
Write-Host ("P1: {0}" -f $p1)
Write-Host ("P2: {0}" -f $p2)
