# SDP Patches

Small optional mods split out of SkillDrivenProgression (see SDP-Core). Each folder is its own Vortex mod;
`tools/Sync-ToVortex.ps1 -Only SDP-Cigarettes` syncs one.

> **Do not deploy the new parts alongside the old all-in-one `SkillDrivenProgression` Vortex mod.** Both define the
> same functions, so redscript would fail to compile. Disable the old mod first (see SDP-Core's README, "Switching over").

| Mod | What it does | Needs |
|---|---|---|
| **SDP-Cigarettes** | Cigarette items and the five-minute Composure buff (+10% skill XP, 15% less recoil and spread). Starter packs on new characters. `compat/CustomQuickslots` is the Custom Quickslots patch | SDP-Core, TweakXL |
| **SDP-CyberwareEx** | Cyberware-EX (nexus 9429) slot customization | Cyberware-EX |
| **SDP-ENCTakedowns** | Takedown rules with Enemies of Night City | ENC |
| **SDP-ScannerDilation** | Scanner time dilation follows Netrunner skill; Native Settings sliders in the shared SDP tab | TweakXL, CET |

## Cigarettes

Use Custom Quickslots' **Consumable Animations → Cigarettes** slot with the
bundled patch; the mod adds no key binding of its own. Smoking is blocked
in combat. New characters receive five Yeheyuan and five Morley once. These
are misc items, not health-booster-slot items.

Smoking grants five minutes of **Composure**: +10% native skill XP and 15%
less recoil kick/base spread on the equipped weapon. Smoking again refreshes
the timer. Consumable Animations is optional for animation; with it installed,
matching vanilla cigarettes also count. Disable Dark Future to avoid overlap.
