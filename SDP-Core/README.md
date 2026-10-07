# SDP Core

Shared base for the SkillDrivenProgression (SDP) parts. SkillDrivenProgression was split on 2026-10-06 into
separate repositories, each installable as its own Vortex mod:

| Repo | What it is | Needs |
|---|---|---|
| **SDP-Core** (this) | The twice-a-second player loop that other parts register with, and a shared skill-type helper | redscript |
| **SDP-Skills** | Skills drive the five attributes, character level from skills, skill checks and rank UI, skill milestones, base-passive and Cyberware Capacity tuning | SDP-Core, TweakXL, CET (+ Native Settings UI for sliders) |
| **SDP-Perks** | The perk system: neural processor, trainable perk shards, Deadeye, shard training v2, encounter XP log and overlay, shard tree | SDP-Core, TweakXL, ArchiveXL, CET (+ Native Settings UI) |
| **SDP-QuickhackCrafting** | Component workbench and quickhack primitives/lab (CET window) | TweakXL, CET |
| **SDP-Combat** | Combat realism: weapon-driven NPC aim and cadence, armour as pieces, cut-down Combat Evolved maneuvers/fear | TweakXL |
| **SDP-Patches** | Four small optional mods: **SDP-Cigarettes** (needs SDP-Core), **SDP-CyberwareEx** (Cyberware-EX slots), **SDP-ENCTakedowns** (takedown rules with Enemies of Night City), **SDP-ScannerDilation** (scanner time by Netrunner skill) | see the Patches README |

Parts only depend on SDP-Core, never on each other. Each part carries a marker module (`SDP.Core`, `SDP.Skills`,
`SDP.Perks`) so later cross-part features can use `@if(ModuleExists("SDP.Perks"))` without making the dependency hard.

## Core loop

`CoreTicker.reds` runs one 0.5 s loop per session. A part registers on player attach:

```swift
public class SDPSkillsTick extends SDPTickListener {
  public func Key() -> CName { return n"SDP.Skills"; }
  public func Tick(player: ref<PlayerPuppet>, seconds: Float) -> Void { player.SDP_MilestoneTick(); }
}
// in a PlayerPuppet.OnGameAttached wrap:
this.SDP_RegisterTick(new SDPSkillsTick());
```

The loop starts with the first registration; re-registering the same key replaces the old listener.
`PlayerPuppet.SDP_LoopTicks()` counts loop passes (shown in the Perks encounter debug line).

## Switching over from the all-in-one mod

1. In Vortex, disable the old **SkillDrivenProgression** mod.
2. Run each repo's `tools/Sync-ToVortex.ps1` for the parts you want, enable the new mods in Vortex, Deploy.
3. Saves carry over: persistent fields keep their names. The shard-XP sliders and the overlay switch keep their
   values (SDP-Perks keeps the CET folder name `SkillDrivenProgression`). The skill-passive, capacity and scanner
   sliders move to the new `SDPSkills` and `SDPScannerDilation` CET mods and start at defaults unless their
   `settings.json` is seeded.

`Launch-LatestSave.cmd` starts the latest complete save (see `tools/Launch-LatestSave.ps1`).
