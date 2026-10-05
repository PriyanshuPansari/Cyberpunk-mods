# Rebuild archive/pc/mod/SkillDrivenProgression.archive from source/*.json.json.
# Usage: .\tools\BuildArchive.ps1 -Cli "C:\path\to\WolvenKit.CLI.exe"   (WolvenKit CLI 8.17.x)
param([Parameter(Mandatory)][string]$Cli)
$root = Split-Path $PSScriptRoot -Parent
$loc = "skilldrivenprogression\localization\en-us"
$src = Join-Path $root "source\$loc"
$dst = Join-Path $root "archive-source\$loc"
& $Cli convert deserialize (Join-Path $src "processor.json.json") -o $dst
& $Cli pack (Join-Path $root "archive-source") -o (Join-Path $root "archive-source")
Move-Item -Force (Join-Path $root "archive-source\archive-source.archive") (Join-Path $root "archive\pc\mod\SkillDrivenProgression.archive")
