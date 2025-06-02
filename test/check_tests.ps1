# Script PowerShell pour vérifier quels tests fonctionnent correctement
$test_files = Get-ChildItem -Path "." -Filter "*.dart"
$results = @{}

foreach ($file in $test_files) {
    Write-Host "============================"
    Write-Host "Testing $($file.Name)..."
    $output = flutter test $file.FullName 2>&1
    $status = if ($LASTEXITCODE -eq 0) { "PASS" } else { "FAIL" }
    $results[$file.Name] = $status
    Write-Host "$($file.Name): $status"
    Write-Host "============================"
}

Write-Host "`nSummary of Test Results:"
Write-Host "============================"
foreach ($key in $results.Keys) {
    Write-Host "$key`: $($results[$key])"
}
Write-Host "============================"

# List passing tests
Write-Host "`nPassing Tests:"
foreach ($key in $results.Keys) {
    if ($results[$key] -eq "PASS") {
        Write-Host "- $key"
    }
}
