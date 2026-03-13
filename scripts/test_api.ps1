param(
  [string]$ProjectId = "paperclip-98294",
  [string]$ApiKey = "AIzaSyC2OA70p2-RhwjkblhXva9yvNm81aKiqSY",
  [string]$Email = "",
  [string]$Password = ""
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Email)) {
  $ts = Get-Date -Format 'yyyyMMddHHmmss'
  $Email = "paperclip.test+$ts@example.com"
}
if ([string]::IsNullOrWhiteSpace($Password)) {
  $ts = Get-Date -Format 'yyyyMMddHHmmss'
  $Password = "Pc2!Test-$ts"
}

$API_BASE = "https://us-central1-$ProjectId.cloudfunctions.net/api"
Write-Host "Project: $ProjectId"
Write-Host "API: $API_BASE"
Write-Host "Using test user: $Email"

function Get-IdToken([string]$email, [string]$password, [string]$apiKey) {
  try {
    $signupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey"
    $body = @{ email = $email; password = $password; returnSecureToken = $true } | ConvertTo-Json
    $resp = Invoke-RestMethod -Method Post -Uri $signupUrl -ContentType 'application/json' -Body $body
    return $resp.idToken
  } catch {
    $msg = $_.ErrorDetails.Message
    if ($msg -and $msg -match 'EMAIL_EXISTS') {
      $signinUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey"
      $body2 = @{ email = $email; password = $password; returnSecureToken = $true } | ConvertTo-Json
      $resp2 = Invoke-RestMethod -Method Post -Uri $signinUrl -ContentType 'application/json' -Body $body2
      return $resp2.idToken
    } else {
      throw $_
    }
  }
}

$TOKEN = Get-IdToken -email $Email -password $Password -apiKey $ApiKey
if (-not $TOKEN) { throw 'Failed to obtain ID token' }
Write-Host "ID token (first 20 chars):" ($TOKEN.Substring(0,20) + '...')

$PARTIE = [Guid]::NewGuid().ToString()
Write-Host "Using partieId: $PARTIE"

# 1) PUT /saves/{partieId}
$savePayload = @{ snapshot = @{ metadata = @{ partieId = $PARTIE }; core = @{}; stats = @{} } } | ConvertTo-Json -Depth 15
Write-Host 'PUT /saves' $PARTIE
$putResp = Invoke-WebRequest -Method Put -Uri ("$API_BASE/saves/$PARTIE") -Headers @{ Authorization = "Bearer $TOKEN" } -ContentType 'application/json' -Body $savePayload -UseBasicParsing
Write-Host 'PUT status:' $putResp.StatusCode
Write-Host $putResp.Content

# 2) GET /saves/{partieId}/latest
Write-Host 'GET /saves/{partieId}/latest'
$getLatest = Invoke-WebRequest -Method Get -Uri ("$API_BASE/saves/$PARTIE/latest") -Headers @{ Authorization = "Bearer $TOKEN" } -UseBasicParsing
Write-Host 'GET latest status:' $getLatest.StatusCode
Write-Host $getLatest.Content

# 3) GET /saves?page=1&limit=50 (escape & with backtick)
Write-Host 'GET /saves?page=1&limit=50'
$uriList = "$API_BASE/saves?page=1`&limit=50"
$getList = Invoke-WebRequest -Method Get -Uri $uriList -Headers @{ Authorization = "Bearer $TOKEN" } -UseBasicParsing
Write-Host 'GET list status:' $getList.StatusCode
Write-Host $getList.Content

# 4) DELETE /saves/{partieId}
Write-Host 'DELETE /saves/{partieId}' $PARTIE
try {
  $delResp = Invoke-WebRequest -Method Delete -Uri ("$API_BASE/saves/$PARTIE") -Headers @{ Authorization = "Bearer $TOKEN" } -UseBasicParsing -ErrorAction Stop
  Write-Host 'DELETE status:' $delResp.StatusCode
} catch {
  # Traiter 404 comme succès (idempotent)
  if ($_.Exception.Response -and $_.Exception.Response.StatusCode.Value__ -eq 404) {
    Write-Host 'DELETE status: 404 (treated as success)'
  } else {
    throw $_
  }
}

# 5) GET /saves (post-delete verification)
Write-Host 'GET /saves (post-delete)'
$getListAfter = Invoke-WebRequest -Method Get -Uri $API_BASE/saves -Headers @{ Authorization = "Bearer $TOKEN" } -UseBasicParsing
Write-Host 'GET list (after) status:' $getListAfter.StatusCode
Write-Host $getListAfter.Content

# 6) POST /analytics/events (best-effort)
$evt = @{ name = 'level_up'; properties = @{ level = 2 }; timestamp = '2025-01-04T12:34:56Z' } | ConvertTo-Json -Depth 10
Write-Host 'POST /analytics/events'
$evtResp = Invoke-WebRequest -Method Post -Uri ("$API_BASE/analytics/events") -Headers @{ Authorization = "Bearer $TOKEN" } -ContentType 'application/json' -Body $evt -UseBasicParsing
Write-Host 'POST analytics status:' $evtResp.StatusCode
