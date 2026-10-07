# SDP Skills

Part of SkillDrivenProgression (see SDP-Core). Requires **SDP-Core**, redscript, TweakXL and CET; Native Settings UI is
optional for sliders. Disable Skillful Attributes and Neuralware while using it.

> **Do not deploy the new parts alongside the old all-in-one `SkillDrivenProgression` Vortex mod.** Both define the
> same functions, so redscript would fail to compile. Disable the old mod first (see SDP-Core's README, "Switching over").

## Skills, attributes and world level

The five native skills retain their ordinary XP sources. Ordinary character
XP no longer raises level. Manual attribute allocation and new Attribute/Primary
point awards are disabled; Relic points remain available. Existing purchased
perks are preserved; an equivalent active vanilla package suppresses the shard's
private copy. Existing unspent Primary points are not migrated or cleared.

| Skill | Derived attribute | Base passive |
| --- | --- | --- |
| Solo | Body | Health |
| Shinobi | Reflexes | Critical chance |
| Engineer | Technical Ability | Armor |
| Netrunner | Intelligence | RAM |
| Headhunter | Cool | Critical damage |

Let `S` be the sum of all five skill levels (each normally 1-60).

- **Skill Rank**, shown in the level UI: `S - 4` (1-296).
- **Compatibility level**: `1 + floor((S - 5) / 5)`, capped by the installed
  game's level limit. Used by systems reading the Level stat.
- **PowerLevel**: `S / 5`, continuously updated through stat modifiers. Used
  by systems such as health and world/item scaling; separate from Level.
- **Attribute**: `3 + 17 * (linked skill - 1) / 59` (3-20).
- **Skill contribution to Cyberware Capacity**: `1.00 * S` by default (S = sum of the five skill levels).
  Other capacity sources and cyberware costs remain in effect.

The Skill Rank bar shows total skill levels gained out of 295, not next-level
XP. Attributes remain for dialogue and requirements. The generated stat patch
redirects attribute-reading modifiers to matching skill-derived proxies.
English cyberware attunement text names the linked skill.

These implemented formulas favor breadth. The [SDP Combat backend plan](design/WORLD_PROGRESSION_BACKEND.md)
is the preferred next step: our own combat rules using native actions and selected
existing mod components, with separate specialist equipment access. Earlier lite
and full-world plans are references; the new backend is not implemented yet.

## Skill milestones

Level 35 doubles the level-15 total. These follow skill levels automatically;
they grant no perk points, shard XP or slots.

| Skill | Level 15 | Level 35 total |
| --- | --- | --- |
| Solo | +5% combat stamina regeneration | +10% |
| Shinobi | -5% sprint/dash stamina cost | -10% |
| Engineer | -5% cyberware cooldowns | -10% |
| Netrunner | -5% quickhack upload time | -10% |
| Headhunter | -5% aiming weapon sway | -10% |

## Settings

The **Skill Driven Progression** Native Settings tab (shared with the other SDP parts) has five passive sliders that
adjust only the built-in skill bonuses, and a Cyberware Capacity per-skill-level slider. CET saves them in
`bin/x64/plugins/cyber_engine_tweaks/mods/SDPSkills/settings.json`.

`tools/GenerateSkillLinks.ps1` rebuilds attribute links (`r6/tweaks/SDPSkills/SkillPassives.yaml`) from a fresh
`SDPFIND` inventory in CET's scripting log.
