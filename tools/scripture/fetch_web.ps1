$ErrorActionPreference = "Stop"

$sourceDirectory = Join-Path $PSScriptRoot "source"
$archive = Join-Path $sourceDirectory "engwebp_usfm.zip"
$expanded = Join-Path $sourceDirectory "engwebp"
$url = "https://ebible.org/scriptures/engwebp_usfm.zip"
$expectedSha256 = "4253589697DC6B5E92695655F2F28792D50E7BE7B9C8E212AF4F4BD18E866C3B"

New-Item -ItemType Directory -Force -Path $sourceDirectory | Out-Null
Invoke-WebRequest -Uri $url -OutFile $archive

$actualSha256 = (Get-FileHash $archive -Algorithm SHA256).Hash
if ($actualSha256 -ne $expectedSha256) {
    throw "WEB source checksum changed. Verify the new upstream archive before converting it."
}

Expand-Archive -Path $archive -DestinationPath $expanded -Force
python (Join-Path $PSScriptRoot "convert_usfm.py") `
    --source $expanded `
    --output (Join-Path $PSScriptRoot "..\..\assets\bible\web.json") `
    --manifest (Join-Path $PSScriptRoot "manifests\web.json")
