# Copy this repo's deployable files into Vortex's staging copy of the mod,
# then click Deploy Mods in Vortex. Vortex deploys only its staging folder.
$root = Split-Path $PSScriptRoot -Parent
$stage = Join-Path $env:APPDATA "Vortex\cyberpunk2077\mods\SDP-Perks"
$folders = @(
  "archive\pc\mod",
  "r6\scripts\SkillDrivenProgression",
  "r6\tweaks\SkillDrivenProgression",
  "bin\x64\plugins\cyber_engine_tweaks\mods\SkillDrivenProgression"
)
foreach ($folder in $folders) {
  $from = Join-Path $root $folder
  if (Test-Path $from) {
    robocopy $from (Join-Path $stage $folder) /E /XF settings.json prototype-recipe.json quickhack-lab-report.txt *.log db.sqlite3 *.vortex_backup /NJH /NJS /NDL | Out-Null
  }
}
Write-Host "Synced to $stage."

