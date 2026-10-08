# SDP TestLab — work in progress

Updated 2026-10-09. **Not release-ready. The controller has not been compiled or
tested in game.** Development was intentionally stopped at the user's request so
work can continue on another device. Do not install this snapshot as a working mod.

This is an independent testing tool for the **base-game SDP overhaul**. Engram
Labyrinth and Dead Signal remain independent planning tracks; neither is a
dependency or implementation target here.

## Written so far

- `r6/scripts/SDPTestLab/Scenarios.reds`: eleven source-selected encounter presets,
  fixed positions from Combat Arena's catalog, and coordinate-drift checks.
- `r6/scripts/SDPTestLab/Controller.reds`: first controller draft, queued state
  changes, site inspection, owned spawns, preparation/start/cleanup/return, sampled
  reports and a current-site observation path. **Uncompiled, with a known string
  construction error; see the handoff.**
- `bin/x64/plugins/cyber_engine_tweaks/mods/SDPTestLab/init.lua`: CET control panel,
  deferred start after closing the overlay, and local JSONL report export. Untested
  against the controller.
- `tools/Build-Package.py`: staged standalone compiler validation and ZIP builder.
  It uses temporary compatibility edits for the older standalone compiler and
  includes Combat Arena rather than excluding that dependency.
- `tools/Test-Package.py`: packaging checks; execution status for this snapshot is
  not established.

Read [REMOTE_HANDOFF.md](../REMOTE_HANDOFF.md) first for exact unfinished work,
validation boundaries and setup on another machine. The
[arena research](../docs/research/COMBAT_ARENA_TESTBED.md) explains the design.

## Intended workflow after qualification

Load a dedicated test save, open CET, select a preset, prepare the site, inspect
floor/routes, confirm the site, inspect attached actors, close CET and start.
Export the report before cleanup. Reload the same baseline save for matched trials:
target respawn does not restore V's supplies, armor, injuries, XP or cooldowns.

The planned presets cover armor/injuries, one/two/four shooters, lost-target
behavior, grenadier support, mantis cyberware, one/two/four runners and a mixed
group. Character names are candidates, not proof that abilities, squad membership,
navigation or hacking work. No artificial health multiplier, forced player-location
stimuli, shop, reward system or test immortality is intended.

Camera/access-point/recon integration uses existing qualified security sites.
The observation path does not construct or validate those networks.

## Local build entry points

Requires a local Cyberpunk installation and its scripts/plugins; remote editing
and review do not. Supply paths appropriate to the new device:

```powershell
python SDP-TestLab/tools/Test-Package.py
python SDP-TestLab/tools/Build-Package.py --game 'D:\Games\Cyberpunk 2077' --compiler 'D:\Tools\redscript-cli.exe'
```

The build should currently be expected to fail until the controller is repaired.
`--skip-compile` only packages source and labels it uncompiled; it is not validation.
Build outputs and full installed-script validation copies stay ignored by Git.

Dependencies: redscript, Codeware, CET, SDP-Combat and
[Combat Arena by whisperOfIndigo](https://www.nexusmods.com/cyberpunk2077/mods/27580).
Install each dependency through its normal distribution. TestLab reads ArenaData
and ArenaSystem; it does not redistribute the arena package or start its survival
loop. The original mod's own dependencies also apply.
