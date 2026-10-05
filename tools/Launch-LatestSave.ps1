[CmdletBinding()]
param(
  [string]$GameExe = 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe',
  [string]$SavesDirectory = (Join-Path $env:USERPROFILE 'Saved Games\CD Projekt Red\Cyberpunk 2077')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
  throw "Cyberpunk executable not found: $GameExe"
}
if (-not (Test-Path -LiteralPath $SavesDirectory -PathType Container)) {
  throw "Cyberpunk saves directory not found: $SavesDirectory"
}
if (Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue) {
  throw 'Cyberpunk is already running. Close it before using this launcher.'
}

$latestSave = Get-ChildItem -LiteralPath $SavesDirectory -Directory | ForEach-Object {
  $saveData = Join-Path $_.FullName 'sav.dat'
  if (Test-Path -LiteralPath $saveData -PathType Leaf) {
    [pscustomobject]@{
      Name = $_.Name
      ModifiedUtc = (Get-Item -LiteralPath $saveData).LastWriteTimeUtc
    }
  }
} | Sort-Object ModifiedUtc -Descending | Select-Object -First 1

if ($null -eq $latestSave) {
  throw "No complete save folder with sav.dat found in $SavesDirectory"
}
if ($latestSave.Name -notmatch '^[A-Za-z0-9_-]+$') {
  throw "Unexpected save folder name: $($latestSave.Name)"
}

Write-Host "Launching Cyberpunk directly into $($latestSave.Name)"
Start-Process -FilePath $GameExe `
  -ArgumentList @("-save=$($latestSave.Name)", '-skipStartScreen') `
  -WorkingDirectory (Split-Path -Path $GameExe -Parent)
