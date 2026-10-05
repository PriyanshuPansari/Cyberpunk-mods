# Copy this repo's deployable files into Vortex's staging copy of the mod,
# then click Deploy Mods in Vortex. Vortex deploys only its staging folder.
$root = Split-Path $PSScriptRoot -Parent
# Usage: .\tools\Sync-ToVortex.ps1 [-Only SDP-Cigarettes,SDP-ScannerDilation]
param([string[]]$Only)
if (-not $Only -or $Only -contains "SDP-Cigarettes") {
  $stage = Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods\SDP-Cigarettes"
  $folders = @(
    "r6\scripts\SDPCigarettes",
    "r6\tweaks\SDPCigarettes"
  )
  foreach ($folder in $folders) {
    $from = Join-Path (Join-Path $root "SDP-Cigarettes") $folder
    if (Test-Path $from) {
      robocopy $from (Join-Path $stage $folder) /E /XF settings.json prototype-recipe.json quickhack-lab-report.txt *.log db.sqlite3 *.vortex_backup /NJH /NJS /NDL | Out-Null
    }
  }
  Write-Host "Synced to $stage."
}
if (-not $Only -or $Only -contains "SDP-CyberwareEx") {
  $stage = Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods\SDP-CyberwareEx"
  $folders = @(
    "r6\scripts\SDPCyberwareEx"
  )
  foreach ($folder in $folders) {
    $from = Join-Path (Join-Path $root "SDP-CyberwareEx") $folder
    if (Test-Path $from) {
      robocopy $from (Join-Path $stage $folder) /E /XF settings.json prototype-recipe.json quickhack-lab-report.txt *.log db.sqlite3 *.vortex_backup /NJH /NJS /NDL | Out-Null
    }
  }
  Write-Host "Synced to $stage."
}
if (-not $Only -or $Only -contains "SDP-ENCTakedowns") {
  $stage = Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods\SDP-ENCTakedowns"
  $folders = @(
    "r6\scripts\SDPENCTakedowns"
  )
  foreach ($folder in $folders) {
    $from = Join-Path (Join-Path $root "SDP-ENCTakedowns") $folder
    if (Test-Path $from) {
      robocopy $from (Join-Path $stage $folder) /E /XF settings.json prototype-recipe.json quickhack-lab-report.txt *.log db.sqlite3 *.vortex_backup /NJH /NJS /NDL | Out-Null
    }
  }
  Write-Host "Synced to $stage."
}
if (-not $Only -or $Only -contains "SDP-ScannerDilation") {
  $stage = Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods\SDP-ScannerDilation"
  $folders = @(
    "r6\scripts\SDPScannerDilation",
    "bin\x64\plugins\cyber_engine_tweaks\mods\SDPScannerDilation"
  )
  foreach ($folder in $folders) {
    $from = Join-Path (Join-Path $root "SDP-ScannerDilation") $folder
    if (Test-Path $from) {
      robocopy $from (Join-Path $stage $folder) /E /XF settings.json prototype-recipe.json quickhack-lab-report.txt *.log db.sqlite3 *.vortex_backup /NJH /NJS /NDL | Out-Null
    }
  }
  Write-Host "Synced to $stage."
}
# Custom Quickslots compatibility patch (with SDP-Cigarettes): overwrite its Consumable Animations
# cigarette definition in its own staging folder (reapply after updating Custom Quickslots).
if (-not $Only -or $Only -contains "SDP-Cigarettes") {
  $cq = Get-ChildItem (Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods") -Directory -Filter "Custom Quickslots*" | Select-Object -First 1
  if ($cq) {
    robocopy (Join-Path $root "SDP-Cigarettes\compat\CustomQuickslots") $cq.FullName /E /NJH /NJS /NDL | Out-Null
    Write-Host "Patched $($cq.Name)."
  }
}

