# Encounter log versions

Balance-test log for SkillDrivenProgression. Each version is one build of
the mod, with the encounter logs recorded while playing it. When the XP rules
change, the current logs are archived as `encounters_vN.*`, emptied, and a new
version section is added here.

Log files live in the CET mod folder:
`Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\SkillDrivenProgression\`

- `encounters.log`: readable. One block per encounter, with skill and shard
  totals and the recent shard awards (the recent-awards lists can overlap
  between encounters).
- `encounters.csv`: one row per encounter, one column per skill and shard.
  After emptying, keep the header row, because the mod writes it only when
  it creates the file.

An encounter covers combat plus 60 s after it ends, so nearby fights merge
into one encounter.

---

## v1: baseline (archived as `encounters_v1.log` / `encounters_v1.csv`)

- **Build:** commit `bc0ef1d` (overlay/onUpdate fix), 2026-10-01
- **Played:** 2026-10-01 01:39 to 01:53 IST, 3 encounters
- **XP rules in effect:**
  - Air Dash: XP only for damaging a hostile within 2 s of a dash.
  - Hack Queue: XP only for a damaging quickhack while the
    `QuickHackQueueCount` stat is 2 or more.
  - Obliteration (shotgun/LMG): +2 XP per damaging hit at Tier 1.

| # | Start | Combat | Solo | Engineer | Netrunner | Headhunter | Obliteration | Air Dash |
|---|-------|--------|------|----------|-----------|------------|--------------|----------|
| 1 | 01:39:45 | 1:04 | 282 | 272 | 82 | 0 | 150 | 6 |
| 2 | 01:43:32 | 1:45 | 231 | 463 | 350 | 18 | 67 | 4 |
| 3 | 01:51:30 | 0:28 | 343 | 343 | 0 | 26 | 83 | 4 |

**Observations**
- **Shotgun XP is awarded per pellet, not per shot.** Up to 14 Obliteration
  awards land in the same second (e.g. 01:39:52, 01:51:41). The duplicate-hit
  check compares the AttackData object, and each pellet has its own. This is
  the main reason shotgun XP is high, possibly more than the level curve
  itself.
- Air Dash awards are rare (3 per encounter), because a hit has to follow
  within 2 s of the dash.
- Hack Queue earned nothing in all three encounters.
- Solo and Engineer skill XP is about 230–460 per encounter, even in a
  28 s fight.

## v2: queue and dash triggers (current `encounters.*`)

- **Build:** commit `fdc9f57` (includes `1aa3764`), 2026-10-01
- **Changes from v1:**
  - Hack Queue: XP when a quickhack is actually queued behind another on an
    enemy: 2/3/4 hacks give sources 1/2/4. Kill and ≥100-damage bonuses are
    still paid on hit. Hooked via
    `QuickHackableQueueHelper.PutActionInQuickhackQueue`.
  - Air Dash: base XP for any ground or air dash while in combat.
    Precision, kill and critical bonuses still need a hit within 2 s.
  - Shard training text and the localization archive were updated to match.
- **To check:** Hack Queue now earns XP; how often Air Dash awards
  (farmable?); shotgun numbers still as in v1 (unchanged).
- **Results (first 2 encounters, 02:01 and 02:08 IST):**

| # | Start | Combat | Solo | Shinobi | Engineer | Netrunner | Headhunter | Obliteration | Air Dash | Hack Queue |
|---|-------|--------|------|---------|----------|-----------|------------|--------------|----------|------------|
| 1 | 02:01:03 | 0:53 | 188 | 0 | 192 | 239 | 60 | 43 | 24 | 4 |
| 2 | 02:08:07 | 3:04 | 419 | 102 | 486 | 415 | 63 | 18 | 26 | 4 |

  - Hack Queue now earns XP (was 0 in v1). Air Dash is up from about 4–6
    to about 25 per encounter.
  - These two rows are padded with empty trigger columns in the csv; they
    were recorded before trigger logging (v2.1).

## v2.1: trigger logging (same `encounters.*` files)

- **Build:** trigger logging commit (see git log), 2026-10-01. The XP rules
  are unchanged from v2, so the log continues in the same files.
- **New metrics per encounter:**
  - **Skill XP events:** how many separate skill XP awards each skill got
    (`skillev_*` columns).
  - **Shard triggers:** how many times each shard's XP condition was met,
    counted whether or not that shard is being trained and even if it is
    already at its cap (`trig_*` columns). The log text also gives the
    per-source breakdown, for example `Obliteration x220 (s1:200 s5:20)`.
  - The overlay shows a `Triggers:` line for the current encounter.
- **Measure-all update (same day):** every training method of every shard is
  counted when its condition is met, whatever the shard's grade and whether
  or not it is being trained. Methods you can't trigger yet simply stay at
  0. Source keys (`sN`) are listed in `TRAINING_METHODS.md`. The only
  exception is Deadeye s4/s12, which count only while Deadeye is trained.

The v2/v2.1 logs are archived as `encounters_v2.log` / `encounters_v2.csv`.

## v3: training v2, all shards (current `encounters.*`)

- **Build:** "Shard training v2 for all shards" commit, 2026-10-01 (the
  Adrenaline/Obliteration pilot commit came first; no fights were logged with it).
- **Changes:** every shard (Deadeye, the 14 families, Vehicle) trains through
  native-style channels (`ShardChannels.reds`; channels in
  `design/shard-channels.json`; numbers in `design/SHARD_XP_MODEL.md`). All v1
  sources stop paying (their s1-s6 triggers are still logged). Thresholds:
  60 / 110 / 150 / 210 / 300 / 430 / 610 / 870 / 1260 / 1830 / 2730 (Vehicle 150);
  XP above a new cap is clamped on load. Shard tooltips rewritten ("Trains from: ...").
- **Channel keys (trigger log):** s11 = the shard's main channel; see
  `SDP_ChannelName` in `ShardChannels.reds` for s12-s15 per shard.
- **Log format (v3.1, same day):** `Shards (by channel)` gives each shard's XP
  split by channel, e.g. `Obliteration +40 (Carnage +35, Obliterate +5)`;
  `Channel triggers` names every v2 channel met (trained or not); `v1 source
  triggers` stays for comparison. The csv adds one `ch_<Shard>_<Channel>`
  XP column per channel; a csv with an older header is renamed
  `encounters_<date>.csv` and a new one started. Shard XP earned out of combat
  (Ninjutsu sneaking) is folded into the next encounter if it starts within
  120 s; stealth runs that never reach combat show only in the overlay.
- **Ninjutsu Shadow (v3.1):** pays only while crouched with an enemy (hostile
  NPC, or any non-friendly NPC in a restricted/hostile zone) or a camera/turret
  within 20 m; staying within 3 m of one spot pays for 5 s at most.
- **To check:** XP per focused fight near the model (~29 early game at x0.48);
  Obliteration s12 on dismembering kills (confirms the flag); Ninjutsu s11 only
  while crouched in restricted/hostile zones; nothing else pays out of combat.
- **Results:** _pending test_

## v3.2: Expansion shards (2026-10-01)
- **Change:** eight new single-grade shards (families 16-23) for Cyberware-EX
  extra slots; see `design/EXPANSION_SHARDS.md`. New columns
  `ch_<Expansion>_System use` and shard XP slots 16-23. Old CSV is rotated
  automatically because the header changed.
- **Chrome:** Tier 4 (grade 7) now gives +4 Cyberware Capacity instead of
  Ambidextrous (moved to Hands Expansion).
- **Context:** played as a normal run with ENC, Night City Alive and
  Reinforcements installed; reviewed periodically, not block-tested.
- **To check:** each Expansion shard records in a few fights with its
  cyberware equipped; extra slots appear in the ripperdoc only while the
  shard is slotted or recorded.
- **Results:** _pending play_

## v3.3: failed encounters (2026-10-01)
- **Change:** dying closes the encounter immediately and logs it (the reload
  would otherwise discard it). New CSV column `outcome` (`survived`/`died`)
  after `combat_seconds`; the readable log marks the header
  `FAILED: player died`. Header changed, so the old CSV is rotated.
- **Note:** XP from a failed run is lost on reload in game, but its row stays
  in the log; filter `outcome=died` out when measuring pacing, keep it for
  difficulty (deaths per fight, kills by rarity before death).
- **Results:** _pending play_

## v3.4: neutralization details (2026-10-01)
- **Source change:** enemies are counted from the game's kill reward
  (`ScriptedPuppet.RewardKiller` with the player as killer) instead of
  killing-blow damage flags, so takedowns, non-lethal knockouts, quickhack and
  status-effect kills count. A defeat finished off later counts once (the row
  is updated). `kills_<rarity>` keeps its meaning (XP-awarding enemies only).
- **New `encounters.csv` columns:** `down_killed`, `down_defeated`,
  `down_unconscious`, `down_rarity_changed` (runtime rarity differs from the
  record's base rarity, e.g. ENC promotions), and `down_by_<method>` for gun,
  melee, cyberarm, quickhack, thrown, explosive, status, takedown, unattributed.
- **New `kills.csv`:** one row per enemy: encounter end/start/outcome, result,
  method, rarity, base rarity, faction, NPC type (Human/Drone/Mech/Android...),
  archetype (role, e.g. NetrunnerT2), power level, awards_xp, name.
- **Method rules:** takedown if the player is in a takedown/grapple state;
  else the player's last hit on that enemy within 15 s (attack type, cyberarm
  by weapon type); else quickhack if one was uploaded within 10 s; else
  unattributed (environment, turrets, companions, scripted deaths).
- **Stealth:** neutralizing an enemy out of combat opens an encounter, so
  stealth runs are logged too (combat_seconds is then the stealth span).
- **To check:** a choke knockout shows unconscious/takedown; a System
  Collapse kill shows quickhack; ENC-promoted enemies show rarity_changed
  (only if ENC changes rarity at runtime rather than in the record).
- **Results:** _pending play_

## v3.5: character snapshot (2026-10-01)
- **Change:** each encounter records the character when it closes (or on
  death): `lvl_<skill>` for the five skills, `player_level`, and `attr_Body`,
  `attr_Reflexes`, `attr_Tech`, `attr_Intelligence`, `attr_Cool` (after
  `outcome`). The readable log has a `Character:` line. Header changed, so the
  old CSV is rotated.
- **Also:** `TakedownRules.reds` drops ENC's Elite/Boss-rarity rule, so only
  break-hold enemies (CanGuardBreak) struggle at once. The base game's rules
  stay (skull-level, MiniBoss and MaxTac enemies break free), as do ENC's
  Body/Cool requirements - the attr_ columns show whether a failed takedown
  was a stat check.
- **Results:** _pending play_

---

## Open balance items
- [ ] Shotgun/Obliteration: count one award per shot instead of per pellet,
      then decide whether the XP curve also needs raising.
- [ ] Anti-farming for the Air Dash and Hack Queue triggers: a cooldown,
      requiring a hostile nearby or aware, or falloff per encounter.
- [ ] Remove the debug counters (`SDP_EncounterDebug`) once logging is
      trusted.
- [ ] Native Settings XP sliders in `init.lua` still cover slots 0-15 only
      (no per-shard tuning for the Expansion shards yet).
- [ ] Rarity cap for NPCs promoted to Boss by ENC if they pay like story bosses.
