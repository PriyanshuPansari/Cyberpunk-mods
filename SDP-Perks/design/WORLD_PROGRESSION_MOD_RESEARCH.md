# World progression: mod research and reuse register

Researched 2026-10-01 using author pages and selected locally staged source.
These are feature candidates, not a recommendation to install all of them.
The [SDP Combat backend plan](WORLD_PROGRESSION_BACKEND.md) is the preferred path,
with selected reuse or original implementation rather than a required overhaul
backend. The [lite proposal](WORLD_PROGRESSION_LITE.md) is a retained reference;
the [full design](WORLD_PROGRESSION_PLAN.md) is a longer-term backlog. A follow-up
[local source audit](WORLD_PROGRESSION_SOURCE_AUDIT.md) inspects the staged copies
and records concrete limitations, including bundled perk changes, time-method
ownership and reinforcement call limits. Use that audit for implementation choices.
The user reports these candidate mods are disabled; presence is not deployment.

The plans are our own proposed designs;
author feature descriptions do not prove compatibility or performance here.

## Primary candidates

| Author source | Useful feature and proposed use | Reuse boundary from author page |
| --- | --- | --- |
| [Enemies of Night City](https://www.nexusmods.com/cyberpunk2077/mods/8467), viperc48 | Faction cyberware, behavior profiles and enemy Sandy tiers. Inspect local modular source for small reusable pieces; do not inherit the whole balance model. | Modification/assets permitted with credit; no sale. Inspect inherited Scissors/SDO contributions separately. |
| [Combat Revolution](https://www.nexusmods.com/cyberpunk2077/mods/20225), ABCdb111 | Enemy archetypes, tactics and cyberware distribution. Candidate source for scoped role/action tuning. | Modification/assets permitted with credit; no sale. Changelog credits ENC knife code: trace that contribution too. |
| [Time Dilation Enhanced](https://www.nexusmods.com/cyberpunk2077/mods/20953), ABCdb111 | Narrow NPC Sandy assignment, behavior, effects and player Kerenzikov contests. First external feature package to inspect for the time prototype. | Modification/assets permitted with credit; whole-file reupload prohibited; no sale. Preserve attribution for extracted contributions. |
| [Time Dilation Overhaul](https://www.nexusmods.com/cyberpunk2077/mods/4931), Cyberpunk THING Team and Friends | Tier-aware time behavior and scanner changes. Reference for edge cases; its much broader player-OS redesign is outside the initial scope. | Modification requires permission; asset use is separately allowed with credit. No wholesale implementation copying under the assumption it is freely licensed. |
| [Reinforcements System](https://www.nexusmods.com/cyberpunk2077/mods/21532), Phoenicia | Interruptible calls, faction/turf heat and reinforcement dispatch. Preferred optional dependency for the first backup experiment. | Modification and asset reuse require permission; use an external adapter or independently implement the behavior. |
| [Immersive Shooting AI](https://www.nexusmods.com/cyberpunk2077/mods/22782), Phoenicia | Accuracy/firing patterns respond to distance, movement, weapons and cyberware. Reference or selected shooting owner; distinguish shooting simulation from tactical decisions. | Modification/assets require permission; dependency or independent implementation initially. |
| [Enemy Rarity Fixes Improved](https://www.nexusmods.com/cyberpunk2077/mods/30958), RelaxItsOk | Enemy identity, rarity, weapon distribution and Sandy tiers. Reference for separating rarity from automatic level/difficulty inflation. | Modification/assets require permission; reference or external dependency rather than copied records. |
| [Gunsensical Reloaded](https://www.nexusmods.com/cyberpunk2077/mods/30771), Maty83, based on FlashInTheFlesh's work | Weapon-specific handling/damage tradeoffs. Compare selected guns before authoring our own grade progression. | Modification/assets permitted with credit, but third-party contributions have separate permissions. No sale or donation points; inspect each reused contribution. |
| [Combat Evolved](https://www.nexusmods.com/cyberpunk2077/mods/29125), DigitalVixen | Faction/role profiles, suppression, coordinated maneuvers and morale. A behavior benchmark; adopting its entire framework would be a separate architecture choice. | Modification/assets require permission. Reference or external integration only at this stage. |

Secondary references: [Harder Gunfights](https://www.nexusmods.com/cyberpunk2077/mods/14544)
isolates firing-delay changes; [Night City Alive](https://www.nexusmods.com/cyberpunk2077/mods/10395)
addresses ambient gang traffic/reactivity. Neither supplies our whole progression
model. Ambient population changes are deferred; both author pages restrict reuse.

## Version observations

Author pages reported the following at research time. Pin the actual archive and
dependencies before use; a page heading is not a tested local installation.

| Mod | Displayed version | Last-update date |
| --- | --- | --- |
| Enemies of Night City | PL-Beta-1.8.8 | 2025-03-31 |
| Combat Revolution | 1.4.2; changelog also mentions 1.4.3 | 2025-08-15 |
| Time Dilation Enhanced | 1.0.0 | 2025-04-13 |
| Time Dilation Overhaul | 2.35 | 2026-09-10 |
| Reinforcements System | 1.2.1 | 2026-08-24 |
| Immersive Shooting AI | 1.1.3 | 2026-09-10 |
| Enemy Rarity Fixes Improved | 1.2 | 2026-09-02 |
| Gunsensical Reloaded | 1.5.1 | 2026-09-02 |
| Combat Evolved | 4.16.8 | 2026-09-25 |

The page links in the candidate table are the sources for this metadata and the
permission summaries. Recheck both when acquiring a different version.

## Local source findings

Vortex staging root inspected:
`C:\Users\incre\AppData\Roaming\Vortex\cyberpunk2077\mods`.
Presence here does not prove that a mod is enabled or deployed.

- ENC staging folder:
  `Enemies of Night City-8467-PL-Beta-1-8-8-Hotfix-1720272238`.
  Its CET `Modules/TimeDilation.lua` writes
  `SandyVSandyTier0ExtraDilation.overrideMultiplerWhenPlayerInTimeDilation`
  and the corresponding tier 1-3 fields. This is a concrete ownership conflict
  with a new time system, not merely thematic overlap.
- Reinforcements staging folder:
  `Reinforcements System 21532 1.2.1 2026-08-24T21-54Z cB3xB0qyh`.
  `GangHandlers/baseHandler.reds` exposes persistent heat, bounty, grace/cooldown
  and dispatch logic; faction handler/data files and YAML rosters are present.
  An adapter is plausible, but no stable public integration API was verified.
- `No Shooting Delay-15559-1-2-fix-1751896989` is also staged. Audit its firing
  changes before testing a replacement shooting owner.

Local native `vanilla-decompiled.reds` exposes `SetIndividualTimeDilation`,
`UnsetIndividualTimeDilation`, and Sandy AI action handling with
`OverrideMultiplerWhenPlayerInTimeDilation`. This supports a prototype, not a
claim that a final quality-contest formula has been validated in-game.

## Acquisition and adaptation procedure

1. First inspect Time Dilation Enhanced, ENC's narrow time/loadout modules and
   Combat Revolution's relevant role records. Reuse staged files where applicable;
   acquire a pinned author archive for anything missing. Store research copies
   outside deployable `r6`, CET and archive directories.
2. For every extracted feature, record mod/version, author URL, archive SHA-256,
   original file/record, permission basis, attribution and dependencies. No hashes
   are claimed here: no new release archive was downloaded in this research pass.
3. Trace third-party contributions separately. Publicly visible source is not by
   itself a reuse grant. Prefer independent implementation where redistribution
   or modification is restricted; an external dependency can remain unmodified.
4. Identify every TweakDB record and wrapped/replaced method it owns. Prototype
   with competing owners disabled in a separate test profile, then test supported
   adapters explicitly. Do not modify the user's live profile to perform research.
5. Port the minimum useful behavior into our own configuration and tests. Preserve
   required credits and notices. Do not copy the source mod's unrelated damage,
   health, perception, economy or player-OS changes as accidental dependencies.

No external mod was installed, deployed or copied into this project's runtime
as part of this plan. The current game version, deployed load order and end-to-end
compatibility remain Phase 0 checks.
