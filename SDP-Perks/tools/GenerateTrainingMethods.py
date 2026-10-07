# Writes TRAINING_METHODS.md from design/shard-channels.json: every shard's
# training methods (XP sources) with the skill they belong to. The "Log" column
# is the key used in encounters.log trigger lines (e.g. "Obliteration x40 (s1:30 s5:10)").
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data = json.loads((root / "design/shard-training.json").read_text(encoding="utf-8"))

# Vanilla perk each shard grade is built from (design catalog + Deadeye order),
# with the game's own perk text (design/vanilla-perk-text.json, extracted from
# lang_en_text.archive onscreens). {float_N} values live in TweakDB, shown as X.
import re
catalog = json.loads((root / "design/other-shard-catalog.json").read_text(encoding="utf-8"))
perk_text = json.loads((root / "design/vanilla-perk-text.json").read_text(encoding="utf-8"))
deadeye_grades = []
for row in (root / "design/DEADEYE_ORDER.md").read_text(encoding="utf-8").splitlines():
    if row.startswith("| Tier"):
        cell = row.strip("|").split("|")[-1]
        deadeye_grades.append([(m[0], int(m[1]) if m[1] else None)
                               for m in re.findall(r"`([A-Za-z0-9_]+)`(?: rank (\d+))?", cell)])

def clean(text):
    text = re.sub(r"<Rich[^>]*>|</>", "", text).replace("\\n", " ").replace("\n", " ")
    text = re.sub(r"\{(float|int)_\d+\}", "X", text)
    return re.sub(r"\s+", " ", text).strip().replace("|", "/")

def perk_line(perk, rank):
    info = perk_text.get(perk, {})
    name = info.get("name") or perk
    descs = info.get("descriptions", {})
    desc = descs.get(f"Level{rank}") if rank else None
    if desc is None:
        desc = descs.get("") or (descs.get("Level1") if len(descs) == 1 else None)
    label = f"**{name}**" + (f" {rank}" if rank and len(descs) > 1 else "")
    return f"{label}: {clean(desc)}" if desc else None

def based_on(shard_name, grade):
    if shard_name == "Vehicle":
        return perk_line("Cool_Left_Milestone_1", None) or "Road Warrior"
    if shard_name == "Deadeye":
        effects = deadeye_grades[grade - 1] if grade - 1 < len(deadeye_grades) else []
        fallback = ""
    else:
        entry = catalog[shard_name]["grades"][grade - 1]
        effects = [(e["perk"].split(".")[-1], e.get("rank")) for e in entry["effects"]]
        fallback = entry["description"]
    parts = [perk_line(p, r) for p, r in effects]
    if not all(parts) and fallback:
        return fallback.replace("|", "/")
    return "<br>".join(x for x in parts if x) or fallback

# Native (vanilla) skill XP sources, read from the game's decompiled scripts
# (RPGManager.AwardExperienceFrom*, crafting, locomotion and grenade code; game 2.x).
NATIVE = [
    ("Solo", "Damage with blunt weapons, fists, other melee and Gorilla Arms", "Full damage XP"),
    ("Solo", "Damage with shotguns, LMGs and HMGs", "Half damage XP; full for Power weapons"),
    ("Solo", "Parry/deflect an attack with a blunt weapon", "0.75 x damage blocked; capped by a stacking limiter"),
    ("Solo", "Overshield absorbs damage from an enemy", "0.25 x shield spent"),
    ("Shinobi", "Damage with assault rifles, SMGs and rifles", "Half damage XP; full for Power weapons"),
    ("Shinobi", "Damage with katanas, swords, machetes, chainswords, other blades and Mantis Blades", "Full damage XP"),
    ("Shinobi", "Parry/deflect an attack with a blade", "0.75 x damage blocked; capped"),
    ("Shinobi", "Movement: dash, dodge, slide, vault, climb", "3-5 points each, paid in batches of 100; capped by a limiter"),
    ("Engineer", "Damage with grenades or the Projectile Launch System", "Full damage XP"),
    ("Engineer", "Damage with Tech weapons", "Extra award equal to the weapon's own damage XP"),
    ("Engineer", "Damaging hit while Sandevistan, Berserk or Optical Camo is active, or a kill with the Tech master buff / Overclock", "Flat 20 per hit (vanilla condition as written)"),
    ("Engineer", "Crafting items", "Per crafted item"),
    ("Netrunner", "Upload a quickhack to a target", "(RAM cost x 0.7 + target level x 0.2) x 0.5; x20 on a target's first hack; x0.3 on devices; capped per target"),
    ("Netrunner", "Damage with quickhacks", "Full damage XP"),
    ("Netrunner", "Damage with Monowire", "Full damage XP"),
    ("Netrunner", "Damage with Smart weapons", "Extra award equal to the weapon's own damage XP"),
    ("Netrunner", "Craft quickhacks", "Fixed amount by quickhack tier"),
    ("Headhunter", "Damage with pistols, revolvers, sniper rifles and precision rifles", "Half damage XP; full for Power weapons"),
    ("Headhunter", "Damage with knives and axes (thrown or melee)", "Full damage XP"),
    ("Headhunter", "Damaging stealth hit (not grenades)", "0.7 x damage XP"),
    ("Headhunter", "Shoot a grenade out of the air", "Flat 100"),
    ("All", "Headshot, weakspot, finisher, perfect charge or Body melee hit", "x1.1 on that hit's damage XP"),
    ("All", "Shooting range / melee training status active", "x2 damage XP"),
    ("All", "Damage XP amount", "Scales with the target's level and rarity and the share of its health you dealt"),
    ("Various", "Device and access-point hacking, forcing doors, extracting parts, quest rewards", "Set in TweakDB reward records, not scripts"),
]
shards = [data["deadeye"]] + sorted(data["families"], key=lambda f: f["id"])
order = ["Solo", "Shinobi", "Engineer", "Netrunner", "Headhunter"]
shards.sort(key=lambda s: (order.index(s["skill"]) if s["skill"] in order else 99, s["name"]))

channels = json.loads((root / "design/shard-channels.json").read_text(encoding="utf-8"))
lines = [
    "# Training methods: native skills and shards (training v2)",
    "",
    "Generated by `tools/GenerateTrainingMethods.py` from `design/shard-channels.json`",
    "(shards) and the game's scripts (native); regenerate after changing channels.",
    "",
    "- **Source:** `Native` = the base game's own skill XP (kept by the mod; Composure",
    "  adds x1.10). Otherwise the shard name.",
    "- **From grade:** the shard grade (1-11) the channel or multiplier applies from.",
    "- **XP:** shard channels are sized like native skill XP (see `design/SHARD_XP_MODEL.md`):",
    "  damage = 5 per enemy Health bar x enemy level curve x rarity; time = 0.7/s; events ~12;",
    "  all x your level's XP multiplier. Grade thresholds: "
    + ", ".join(str(t) for t in channels["thresholds"]) + f" (Vehicle {channels['vehicleThreshold']}).",
    "- **Settings:** the family's 0-500% XP slider multiplies channel XP after its base",
    "  limiter. Fractional awards persist across saves; 0% pauses awards without clearing progress.",
    "- **Based on:** the vanilla perk(s) the shard grants at that grade, with the game's own",
    "  perk text (numbers shown as X; they live in TweakDB).",
    "",
    "| Skill | Source | From grade | Training channel / multiplier | XP | Based on (vanilla perk at that grade) |",
    "|-------|--------|-----------:|-------------------------------|----|---------------------------------------|",
]
for skill in order + ["All", "Various", "None"]:
    for native_skill, method, amount in NATIVE:
        if native_skill == skill:
            lines.append(f"| {skill} | Native | - | {method} | {amount} | - |")
    for shard in shards:
        if (shard["skill"] or "None") != skill:
            continue
        for unlock, text in channels["channels"][shard["name"]]:
            lines.append(f"| {skill} | {shard['name']} | {unlock} | {text} | channel | {based_on(shard['name'], unlock)} |")
lines += [
    "",
    "## Notes",
    "",
    "- The encounter log counts channel triggers as `s11`+ per shard (see `ShardChannels.reds`,",
    "  `SDP_ChannelName`); the old v1 source triggers `s1`-`s6` are still counted for comparison.",
    "- Deadeye reload sources (v1 s4/s12) are gone in v2.",
    "",
]
(root / "TRAINING_METHODS.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
print("wrote TRAINING_METHODS.md", len(lines))
