# Expansion shards (Cyberware-EX slots)

Status: implemented 2026-10-01, untested in game. Data: `design/expansion-shards.json`.

Cyberware-EX Extended mode adds extra cyberware slots gated on
vanilla perks. SDP replaces that gating with eight standalone, single-grade
**Expansion shards** (families 16-23), so slots don't depend on the Chrome tree.

| Family | Shard | Body system | Extra slots | "In use" (x2 XP) |
|---:|---|---|---:|---|
| 16 | OS Expansion | Operating system | 2 | Sandevistan, Berserk or Overclock active |
| 17 | Frontal Cortex Expansion | Frontal cortex | 2 | quickhack uploaded in the last 5 s |
| 18 | Cardiovascular Expansion | Circulatory system | 1 | Health item / Blood Pump in the last 10 s |
| 19 | Nervous System Expansion | Nervous system | 1 | Kerenzikov active |
| 20 | Integumentary Expansion | Integumentary system | 2 | Optical Camo active |
| 21 | Arms Expansion | Arms | 1 | cyberarm hit in the last 5 s |
| 22 | Hands Expansion | Hands | 1 (+ vanilla Ambidextrous slot) | gun hit in the last 5 s |
| 23 | Legs Expansion | Legs | 1 | dash/slide/vault/climb in the last 5 s |

- **Unlock:** while slotted in the processor, or permanently once recorded.
- **Training (channel "System use"):** combat time with that system's cyberware
  equipped: half the shared time rate (0.7/s base) with one item, the full rate
  with two or more, x2 while in use; 10 s window cap. Record at 150 XP.
- **Where to get them:** the same netrunner vendors as the other base shards.
- **Chrome change:** Chrome Tier 4 (grade 7) no longer grants Ambidextrous (the
  vanilla extra Hands slot); it grants **Chrome Calibration: +4 Cyberware
  Capacity** (`SDPChromeCalibration`). Ambidextrous now comes from the Hands
  Expansion shard.

## How it works

- `CyberwareExSlots.reds` defines `CyberwareEx.Customization.UserConfig`, which
  switches Cyberware-EX to custom mode with the same areas/counts as Extended
  mode. Each slot's perk requirement uses a sentinel level `100 + family`
  (116-123). Without Cyberware-EX the file compiles to nothing.
- `ShardExpansion.reds` wraps `EquipmentSystemPlayerData.IsSlotLocked`: a slot
  whose prereq has a sentinel level is unlocked when
  `SDP_FamilyActiveGrade(family) >= 1`; every other slot is untouched. It also
  wraps `InitializeEquipSlotsFromRecords` so cyberware in those slots survives
  a save load. (`PlayerIsNewPerkBoughtPrereq.IsFulfilled` can't be wrapped:
  it overrides a native method, its bytecode name is unmangled, and redscript
  0.5 reports UNRESOLVED_METHOD.)
- Family count is now `SDP_FamilyCount()` (23); `SDP_FamilyMaxGrade` is 1 for
  Vehicle and the Expansion shards.

## Notes

- Keep the Cyberware-EX Extended-mode file installed or not; custom mode wins.
- Cyberware-EX's Override mode (buying slots at ripperdocs) is not used.
- **Removal lock:** an unrecorded Expansion chip can't be removed or swapped
  out of the processor while cyberware sits in a slot it unlocks (for Hands,
  also the Ambidextrous slot); the game shows a warning instead. Unequip that
  cyberware first. Recorded chips can always be removed (slots stay unlocked).
  Implemented by wrapping `ItemModificationSystem.RemoveItemPart`,
  `SwapItemPart` and `InstallItemPart` (`ShardExpansion.reds`). Unequipping
  the whole processor is not blocked yet.
