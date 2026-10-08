# Cyberpunk mods

See [DEPLOYMENT.md](DEPLOYMENT.md) for updating the split mods, Vortex staging,
validation, backups and recovery.

Cyberpunk 2077 mods by PriyanshuPansari. They started as one mod, SkillDrivenProgression (SDP): skill-driven leveling, a reworked perk system and realistic combat, with one rulebook for V and NPCs. That mod is now split into parts. Each folder below is a separate mod, installed as its own Vortex mod by copying the folder's `r6`, `bin` and `archive` contents.

| Folder | What it is | Needs |
|---|---|---|
| [SDP-Core](SDP-Core) | Shared player loop and helpers used by the other parts | redscript |
| [SDP-Skills](SDP-Skills) | Skills drive attributes and character level; skill checks, rank UI, milestones, passive and capacity tuning | SDP-Core, TweakXL, CET (Native Settings UI optional) |
| [SDP-Perks](SDP-Perks) | Perk system: neural processor, trainable perk shards, Deadeye, encounter XP log, shard tree | SDP-Core, TweakXL, ArchiveXL, CET |
| [SDP-QuickhackCrafting](SDP-QuickhackCrafting) | Quickhack Designer (Crafting menu tab and CET window): build quickhacks from primitives and run them as cyberdeck program chips; recreations of every native quickhack tier with a comparison meter; primitives lab | TweakXL, CET; Codeware for the native menu |
| [SDP-Combat](SDP-Combat) | Combat realism: weapon-driven NPC aim and cadence, blind fire, armour as pieces, cut-down Combat Evolved maneuvers and fear | TweakXL |
| [SDP-Patches](SDP-Patches) | Small optional mods: Cigarettes, Cyberware-EX slots, ENC takedowns, scanner dilation | per mod |

Every part needs redscript and runs on game 2.3x with redscript 0.5.31. SDP-Core's README describes how to switch over from the old all-in-one mod. Never deploy the parts alongside the old `SkillDrivenProgression` mod: both define the same functions, so the script compile fails.

## Design and research

**Current handoff (2026-10-09):** [Continue remotely](REMOTE_HANDOFF.md).
[SDP-TestLab](SDP-TestLab/README.md) is an unfinished arena/controller draft for
base-game mod testing, not a release-ready package. The engram and zombie modes
remain independent tracks.

[Overhaul vision](docs/OVERHAUL_VISION.md) records the current direction, explicit
decisions and open proposals across progression, combat, cyberware, netrunning and
reconnaissance. It takes precedence over conflicting older design proposals.

[Systems research](docs/research/README.md) maps that direction to native game code
and existing SDP implementations, with high-level and low-level reports, a dedicated
AI behavior study, checked source references and a concrete validation backlog.
Research findings distinguish inspected code from historical measurements and
behavior that still needs an in-game test.

[Alternate mode plans](docs/modes/README.md) specify the Engram Labyrinth and
Dead Signal concepts: separate stories, gameplay loops, shared technical contracts,
engine feasibility tests and staged prototypes. These are plans, not deployed mods.

## History

Each folder was imported from its own local repository, and that repository's commit history is kept.

## Credits

`SDP-Combat/r6/scripts/SDPCombat/CE` is a cut-down copy of DigitalVixen's **Combat Evolved** 4.16.8 ([Nexus 29125](https://www.nexusmods.com/cyberpunk2077/mods/29125)).
