# World progression lite: implementation audit

Read-only inspection, 2026-10-01. These findings concern locally staged source,
not verified gameplay. The user reports the candidates are disabled.
[31 file fingerprints](world-progression-source-manifest.json) identify mod folder,
relative path and SHA-256. These are individual source hashes, not archive hashes
or a complete deployed-mod inventory. Decisions are in [the lite plan](WORLD_PROGRESSION_LITE.md).

Paths below are relative to each mod's staging directory under
`C:\Users\incre\AppData\Roaming\Vortex\cyberpunk2077\mods`.

## ENC PL-Beta-1.8.8 hotfix

CET root: `bin/x64/plugins/cyber_engine_tweaks/mods/Enemies of NC/`.

- `init.lua` loads Native Settings, Base and other modules on `onInit`. Its
  constructor does not return a configuration object/API for another mod.
- `Modules/Native Settings.lua:32` onward reads `Data/config_new.json` into Lua
  variables. Lines 324-327, for example, update the setting, save it and execute
  `reloadable_config.lua`. Editing JSON alone does not execute that callback.
- `Modules/Base.lua:82-94` creates T1/T2/T3 HP/damage multipliers and appends them
  to tier ability stat groups. Lines 427-440 attach Boss/Elite HP/damage to rarity
  groups. Overlapping groups can compound.
- `Modules/reloadable_config.lua:4-25` writes these scalar output fields; later
  entries separately tune named bosses. Boss HP, regeneration, damage caps and
  weakspots need separate review.
- `Modules/Base.lua:3-6` appends without deduplicating. Re-running initialization
  is not an appropriate preset refresh.
- `Modules/TimeDilation.lua:5-8` writes four fixed
  `SandyVSandyTierNExtraDilation.overrideMultiplerWhenPlayerInTimeDilation` flats.
  `Base.lua:5443-5489` creates tier actions/selector. The referenced condition
  `SandyVSandyOROR` was not defined in the searched text files; inspect its resolved
  TweakDB form before extending activation to scanning.

Decision: primary backend with an allowlist of output records after initialization.
The tier infrastructure is useful but does not itself implement deck-quality
comparison. ENC's UI callbacks remain competing writers unless managed explicitly.

## Reinforcements System 1.2.1

Source root: `r6/scripts/ReinforcementsSystem/`.

- `Settings.reds:60`: `callsLimit` exists, default zero/unlimited. Grace, initial
  heat, call duration and special-call toggles are also exposed.
- `GangHandlers/baseHandler.reds:8-15`: BaseHandler has persistent heat/wave data;
  `callsPerformed` is non-persistent and belongs to each faction handler.
- `baseHandler.reds:83-93`: grace depends on actual Street Cred and bounty.
  Lines 144-170 add heat, turf and rapid-response contributions.
- `baseHandler.reds:109-129`: PrepareToSpawnVehicles clamps roster heat to 20;
  SpawnVehicles requests a dynamic vehicle wave at distance 25, in front of the
  player. That clamp is not a wave count. `waveCounter` supplies an identifier.
- `baseHandler.reds:195-200`: `callsLimit < callsPerformed` permits equality,
  hence a third ordinary attempt when both values equal 2.
- `HandleReinforcementCall:133` checks cooldown but not the call limit. It
  increments callsPerformed at 179 and dispatches at 192. Direct calls appear in
  `Abilities/biomons.reds:44`, `TickSystem.reds:226` and
  `ReinforcementSystem.reds:347`. Fixing only the attempt method misses those paths.

Decision: external dependency with an original dispatch guard and shared episode
accounting. The initial lite assertion that these classes cannot be wrapped was
unsupported: public non-abstract methods are candidate hooks. A compile probe and
override/call-path tracing remain required. No source patch or runtime proof was
performed during this audit.

## They Will Remember 2.6.7

Under `r6/scripts/They_Will_Remember/`, `Settings.reds:213,220` enables normal and
quest reinforcements by default; retaliation is separately configured. The package
contains Reinforcements/Monitoring, Reinforcements/Reinforcements, squads,
Retaliation and Spawner implementations. `ReinforcementsStubs.reds` conditionally
provides stubs when `TheyWillRemember.Reinforcements` is absent.

Decision: optional faction memory later, backup switches off when RS owns dispatch,
retaliation separately evaluated. It is not passive memory alone. The author page
requires permission for modification/asset reuse: retain an external dependency.
[Author source](https://www.nexusmods.com/cyberpunk2077/mods/19747).

## Other enemy and time systems

| Candidate | Source evidence | Integration consequence |
| --- | --- | --- |
| Combat Revolution, local folder `Combat-20225-1-4-3-1755242153` | CET Combat/init.lua loads several modules. Modules/No Shooting Delay.lua sets RealisticFight=true, enumerates AIPatternDelay records and writes zero delays. Separate TweakXL files alter NPCs, companions and player cyberware | Alternative backend, not AI-only addon. Local folder identifies 1.4.3 despite earlier page-header ambiguity |
| Combat Evolved 4.16.8 | GBP_ChromeDist.reds:8-25 matches faction/archetype/tier at spawn. GBP_Config.reds:185 defaults player HP override off. GBP_PlayerHP.reds removes all Health modifiers and supplies a flat target when enabled, checked every five seconds | Credible separate trial; verify frameworks and keep player HP override off. Do not combine chrome/stat owners with ENC |
| Time Dilation Enhanced, staged as Sandevistan Enhanced 1.0.0 | SandevistanVersusSandevistan.yaml supplies multiplier 8 and override 32. SandevistanCondition.yaml selects player Sandy/Kerenzikov status effects | Not a deck-quality comparison or explicit scanner trigger; overlaps ENC's action family |
| TDO 2.35 | EnemySandevistanRework/RecordLogicExtensions/sandevistanAdditionalFunctions.reds:210-229 compares enemy base speed to reciprocal active player Sandy dilation. wrappers.reds:79-80 wraps SetTimeDilation. TDO/Scanning/ScanningTimeDilation.reds owns scanner charge and suppresses native focus dilation | Strong alternative, substantial ownership scope; not a drop-in addition to ENC + SDP scanner |
| Enemy Rarity Fixes Improved 1.2 | enemy_competitive_sandevistan.reds:1 replaces SetTimeDilation, chooses hardcoded tier overrides 2/2.5/3, then unsets/reapplies individual dilation | It owns a time method as well as rarity data. Keep off in the primary stack |

TDO's settings class initializes mk5Strength to 85, but ESR_Settings obtains 95
from ESRConfig.Mk5Strength(). Trace effective getter paths before changing a
visible default; not every settings-looking field controls runtime behavior.

## Shooting and weapons

- HarderGunfights/init.lua writes TimeBetweenHits difficulty/cover multipliers
  and miss offsets. This changes allowed hits/intentional misses, not simply
  pauses between bursts.
- NoShootingDelay/init.lua:3 requires Modules/main.lua. Only functions, Language
  File and Native Settings modules accompany it in the inspected staging copy;
  main.lua is absent. It multiplies shooting-pattern delays. Resolve packaging and
  verify reload behavior before recommending this copy for activation. This is a
  static finding, not an observed runtime error.
- No standalone Immersive Shooting AI folder was found in the inspected staging
  inventory; it remains an online reference rather than locally audited source.
- Gunsensical Reloaded has npc_damage, shooting_patterns, prices,
  encounter_balancing and **.tweak perk files** beyond weapon YAML.
  `r6/scripts/zzz_GunsensicalReloaded/PerkChanges.reds:1` replaces the blade-finisher
  condition and checks native perk purchase state. The body/reflexes `.tweak`
  files redefine packages that can affect SDP's `$base` shard clones. Example NPC
  damage records directly replace weapon DPS. A YAML-only audit misses overlap.

Decision: dependency/provenance allowlist for selected weapons; no incidental
perk, economy or NPC damage import. Pressure changes follow damage calibration.

## More Levels 1.3.0

`r6/scripts/MoreLevels/Settings.reds` defaults character cap to 79, Street Cred to
100, custom capacity scaling on and XP multiplier hooks on. These are source
defaults, not verified saved settings. `MoreLevels.reds:34-40` updates multiple
systems; OnCurveReady supplies custom XP curves. Merely setting character cap to
60 does not make it inert. Leave it off for lite. Examining XP curves does not
constitute auditing every native scaling curve.

## Limits of the evidence

No mod was enabled, no game was launched and no third-party code was copied or
modified. Text inspection does not resolve archived records, establish load order,
validate animations/clocks or prove a wrapper compiles. Those are explicit
milestone gates. Local source availability does not grant redistribution rights;
the earlier permission research still governs any future extraction.
