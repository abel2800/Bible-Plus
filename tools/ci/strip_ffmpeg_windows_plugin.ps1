# Removes ffmpeg_kit_flutter_new from the Windows desktop build.
#
# The plugin downloads ~47MB of MinGW FFmpeg DLLs and patches them with
# editbin during CMake configure. That path is brittle on CI and is only
# needed for Verse Studio MP4 export, which already falls back to system
# `ffmpeg` or animated GIF on desktop.
#
# Usage (after flutter pub get):
#   powershell -ExecutionPolicy Bypass -File tools/ci/strip_ffmpeg_windows_plugin.ps1

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$cmake = Join-Path $root 'windows\flutter\generated_plugins.cmake'
$registrant = Join-Path $root 'windows\flutter\generated_plugin_registrant.cc'

if (-not (Test-Path $cmake)) {
  throw "Missing $cmake. Run 'flutter pub get' first."
}
if (-not (Test-Path $registrant)) {
  throw "Missing $registrant. Run 'flutter pub get' first."
}

$cmakeText = Get-Content -Path $cmake -Raw
$cmakeUpdated = [regex]::Replace(
  $cmakeText,
  '(?m)^\s*ffmpeg_kit_flutter_new\r?\n',
  ''
)
if ($cmakeUpdated -eq $cmakeText -and $cmakeText -notmatch 'ffmpeg_kit_flutter_new') {
  Write-Host 'FFmpeg Kit already absent from generated_plugins.cmake'
} else {
  Set-Content -Path $cmake -Value $cmakeUpdated -NoNewline
  Write-Host 'Removed ffmpeg_kit_flutter_new from generated_plugins.cmake'
}

$ccText = Get-Content -Path $registrant -Raw
$ccUpdated = [regex]::Replace(
  $ccText,
  '(?m)^#include <ffmpeg_kit_flutter_new/.+>\r?\n',
  ''
)
$ccUpdated = [regex]::Replace(
  $ccUpdated,
  '(?ms)^\s*FFmpegKitFlutterPluginRegisterWithRegistrar\(\s*\r?\n\s*registry->GetRegistrarForPlugin\("FFmpegKitFlutterPlugin"\)\);\r?\n',
  ''
)
if ($ccUpdated -eq $ccText -and $ccText -notmatch 'ffmpeg_kit|FFmpegKit') {
  Write-Host 'FFmpeg Kit already absent from generated_plugin_registrant.cc'
} else {
  Set-Content -Path $registrant -Value $ccUpdated -NoNewline
  Write-Host 'Removed FFmpeg Kit registration from generated_plugin_registrant.cc'
}

Write-Host 'Windows FFmpeg Kit plugin stripped for desktop build.'
