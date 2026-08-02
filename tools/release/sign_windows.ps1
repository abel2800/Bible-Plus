$ErrorActionPreference = "Stop"

$certificate = $env:BIBLEPULSE_WINDOWS_CERTIFICATE
$password = $env:BIBLEPULSE_WINDOWS_CERTIFICATE_PASSWORD
$timestampUrl = $env:BIBLEPULSE_WINDOWS_TIMESTAMP_URL
if ([string]::IsNullOrWhiteSpace($timestampUrl)) {
    $timestampUrl = "http://timestamp.digicert.com"
}

if ([string]::IsNullOrWhiteSpace($certificate) -or
    [string]::IsNullOrWhiteSpace($password)) {
    throw "Windows signing certificate variables are required."
}
if (-not (Test-Path $certificate)) {
    throw "Windows signing certificate was not found."
}

$signtool = Get-Command signtool.exe -ErrorAction Stop
$executables = Get-ChildItem "build/windows/x64/runner/Release" `
    -Include *.exe,*.dll -Recurse
if ($executables.Count -eq 0) {
    throw "No Windows release binaries were found."
}

foreach ($binary in $executables) {
    & $signtool.Source sign /fd SHA256 /f $certificate /p $password `
        /tr $timestampUrl /td SHA256 $binary.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed for $($binary.FullName)"
    }
}

Write-Host "Signed $($executables.Count) Windows release binaries."
