# Cyberpunk systems research

Research date: 2026-10-08. Purpose: establish how Cyberpunk implements the systems
in [our overhaul vision](../OVERHAUL_VISION.md), and where the current SDP code
already changes them.

## Read in this order

1. [High-level systems](HIGH_LEVEL_SYSTEMS.md): native gameplay model, current SDP
   changes, gaps and design consequences across all eleven domains.
2. [Low-level systems](LOW_LEVEL_SYSTEMS.md): implementation paths, formulas,
   candidate hooks, state models and integration boundaries.
3. [AI behavior](AI_BEHAVIOR.md): perception, decision selection, tickets,
   action execution, netrunners, grenades, suppression and squad behavior.
4. [Validation and implementation backlog](VALIDATION_BACKLOG.md): concrete
   experiments, source-level risks and the order in which to resolve them.
5. [Source map](SOURCE_MAP.md): 58 checked anchors, with file/line links;
   [source-evidence.json](source-evidence.json) fingerprints 26 source files.
6. [Combat Arena testbed assessment](COMBAT_ARENA_TESTBED.md): audited installed
   source, survival-mode confounders, a proposed isolated controller and test presets;
   [arena evidence manifest](combat-arena-evidence.json) fingerprints its ten files.

## Scope and evidence quality

This is a completed static research baseline, not a claim that the full engine has
been reverse engineered or that the proposed overhaul has been tested in game.

| Label | Meaning |
| --- | --- |
| SOURCE | Directly inspected script implementation or current mod code |
| DATA | Inspected stored TweakDB dump; values belong to that capture |
| HISTORICAL | Earlier project audit or measurement, not reproduced in this pass |
| DOCUMENTED | Official game notes or tool/mod author documentation |
| INFERENCE | Consequence suggested by inspected code, requiring runtime confirmation |
| PROPOSAL | Our intended design or implementation, not native behavior |

The installed Steam executable reports product version **2.31**, file version
**3.0.5294808**. The existing `vanilla-decompiled.reds` and `final-inspect.reds`
snapshots are byte-identical. Earlier project notes describe this decompilation
as 2.31; it was not regenerated or matched to a fresh compiled bundle in this pass.
The executable version does not by itself certify the snapshot's provenance.

The quickhack dump manifest identifies **Build 13**, 77 programs, player level 49,
Intelligence 20 and maximum RAM 41. It records 162 depth-limited occurrences.
The compact data round-trip was verified by the original compressor. Derived
values are build-dependent, and unexpanded references are not absent behavior.
Build 14 source changes do not turn the stored dump into a Build 14 capture.

Inspected local source does not prove the same files are deployed or enabled.
No live mod inventory or fresh runtime TweakDB capture was performed. No game was
launched, gameplay code changed, or mod deployed for this research.
The later Combat Arena assessment separately compared its ten staged files with
the game-directory copies and found exact matches; live activation remains untested.

## Main findings

- Much of the required infrastructure exists: action records, status effects,
  packages, sensors, threat tracking, squad tickets, equipment and crafting.
- Network permissions, persistent treated injuries, observation freshness and
  consistent shared resource rules require new state and policy.
- NPC hacking has a `BeingHacked` gate, a target upload pool, a shared HUD bar and
  a player-side attacking-runner ID. Raising ticket counts alone cannot implement
  independent simultaneous attackers.
- Native armor is a damage multiplier, with specific penetration and hit-shape
  branches. Our current armor replacement is a different model and already has
  stateful integrity and penetration rolls.
- Current limb crippling runs before armor. Current armor mutation lacks an
  explicit projection guard even though native damage previews call that stage.
- Native minimap reveal logic is conditional, not literally universal omniscience.
  It still differs from the desired source-and-timestamp contact model.
- The current custom-program executor is explicitly player-to-NPC. Sharing it
  with enemy runners requires separating effect semantics from actor execution.
- Existing skill milestones have already been partially modified. The earlier
  conversation's description of reward redesign as entirely unstarted was inaccurate.
- Native `Humanity`/`HumanityAvailable` names participate in cyberware capacity.
  Removing a psychological humanity mechanic must not blindly remove these stats.

## Reproduction

From the workspace root:

```powershell
python tools/research/BuildEvidenceIndex.py
```

The generator validates each anchor and fingerprints source files. It only rewrites
the research source map and manifest. It does not establish runtime behavior.

For one stored quickhack example, from `SDP-QuickhackCrafting`:

```powershell
python tools/ExplainNativeQuickhack.py "Overheat T3"
```

That command was run successfully during this pass. Its output is a reading of the
existing capture, not a new measurement.

## External references checked

- [CDPR Update 2.0](https://www.cyberpunk.net/en/news/49060/update-2-0): the relevant
  modern design baseline; not a specification of every later patch.
- [Better Netrunning author description](https://www.nexusmods.com/cyberpunk2077/mods/2302):
  reference design; source package and current compatibility were not audited here.
- [redscript repository](https://github.com/jac3km4/redscript): compiler/decompiler tooling.
- [TweakXL repository](https://github.com/psiberx/cp2077-tweak-xl): TweakDB modification layer.
- [Codeware repository](https://github.com/psiberx/cp2077-codeware): scripting framework.
- [WolvenKit repository](https://github.com/WolvenKit/WolvenKit): resource inspection/editing.
- [Modding documentation on behavior files](https://wiki.redmodding.org/cyberpunk-2077-modding/for-mod-creators-theory/files-and-what-they-do/file-formats/behaviors-.behavior-files):
  author explanation of graph/record relationships; the page explicitly notes that
  this format is still being studied. No extracted `.behavior` graph was audited here.

Earlier local audits remain useful references, especially
[combat realism](../../SDP-Combat/design/SDP_COMBAT_REALISM_PASS.md),
[backend architecture](../../SDP-Combat/design/WORLD_PROGRESSION_BACKEND.md) and
[mod integration](../../SDP-Perks/design/WORLD_PROGRESSION_SOURCE_AUDIT.md).
Use the qualifications in this research where their older conclusions overreach
the underlying code or conflict with the latest design direction.
