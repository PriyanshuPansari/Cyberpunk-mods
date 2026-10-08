"""Fingerprint and validate the source anchors used by the overhaul research.

Run from any directory: python tools/research/BuildEvidenceIndex.py
Only writes docs/research/source-evidence.json and SOURCE_MAP.md.
Does not modify, deploy, or execute game/mod code.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "research"
NATIVE = "vanilla-decompiled.reds"
COMBAT = "SDP-Combat/r6/scripts/SDPCombat/"
QH = "SDP-QuickhackCrafting/r6/scripts/SDPQuickhackCrafting/"
SKILL = "SDP-Skills/r6/scripts/SDPSkills/"
PERK = "SDP-Perks/r6/scripts/SkillDrivenProgression/"

# ID, file, first line, last line, text that must occur on the first line, subject.
ANCHORS = [
    ("N-xp", NATIVE, 76538, 76670, "func AddExperience", "Native proficiency XP"),
    ("N-rewards", NATIVE, 76474, 76504, "ProcessProficiencyPassiveBonus", "Skill rewards and restoration"),
    ("N-perks", NATIVE, 77159, 77227, "func BuyNewPerk", "Perk purchase and special side effects"),
    ("N-equip", NATIVE, 57003, 57021, "CheckEquipPrereqs", "Equipment prerequisites"),
    ("N-equip-packages", NATIVE, 57391, 57403, "GetSlotGLPs", "Slot and item gameplay packages"),
    ("N-capacity", NATIVE, 40737, 40737, "HumanityAvailable", "Capacity stat naming"),
    ("N-crafting", NATIVE, 67025, 67116, "func CraftItem", "Recipe and inventory transaction"),
    ("N-upgrade", NATIVE, 67484, 67529, "func UpgradeItem", "Item upgrade transaction"),
    ("N-damage", NATIVE, 79912, 79938, "func ProcessPipeline", "Real and projected damage pipelines"),
    ("N-preprocess", NATIVE, 80154, 80213, "func PreProcess", "Preprocessing and localized damage order"),
    ("N-process", NATIVE, 80454, 80476, "func Process(", "Damage processing and projection gate"),
    ("N-target-mods", NATIVE, 81502, 81506, "CalculateTargetModifiers", "Armor call site"),
    ("N-armor", NATIVE, 81868, 81942, "func ProcessArmor", "Native armor calculation"),
    ("N-friendly-fire", NATIVE, 81710, 81736, "hitEvent.target ==", "Self damage and friendly-fire filters"),
    ("N-charges", NATIVE, 191729, 191765, "class ConsumablesChargesHelper", "Consumable charge pools"),
    ("N-charge-listeners", NATIVE, 191859, 191973, "class BaseChargesStatListener", "Charge UI and grenade recharge"),
    ("N-heal-listener", NATIVE, 233814, 233824, "class HealingItemsChargeStatListener", "Healing recharge feedback"),
    ("N-hack-cost", NATIVE, 26319, 26490, "func GetCost", "RAM calculation and perk branches"),
    ("N-hack-effects", NATIVE, 26065, 26111, "func ProcessStatusEffects", "Action recipient/effect application"),
    ("N-queue", NATIVE, 116748, 116864, "class QuickHackableQueueHelper", "Player quickhack queue"),
    ("N-ice", NATIVE, 117293, 117299, "func GetICELevel", "ICE and level coupling"),
    ("N-access", NATIVE, 113573, 113625, "func SetIsBreached", "Access-point breach state and propagation"),
    ("N-incoming-hack", NATIVE, 21852, 21908, "func OnHackTargetEvent", "BeingHacked gate and retry"),
    ("N-player-hacker", NATIVE, 43595, 43599, "func OnHackTargetEvent", "Player tracks attacking netrunner ID"),
    ("N-ai-upload", NATIVE, 240050, 240114, "class AIQuickHackAction", "NPC upload pool and timing"),
    ("N-upload-listener", NATIVE, 185347, 185425, "class UploadFromNPCToPlayerListener", "Upload HUD and save lock"),
    ("N-ai-hack", NATIVE, 473098, 473189, "class AISubActionQuickHack", "AI hack subaction and proxy visualization"),
    ("N-proxy", NATIVE, 156656, 156708, "func GetNetrunnerProxy", "Security sensor and squad proxy selection"),
    ("N-tag", NATIVE, 103227, 103245, "func TagObject", "Tag/reveal/HUD fanout"),
    ("N-minimap", NATIVE, 401540, 401618, "func Update", "Minimap reveal conditions"),
    ("N-sensor", NATIVE, 143537, 143585, "func GetCurrentTargets", "Sensor target lists and shutdown"),
    ("N-control", NATIVE, 146477, 146565, "class TakeOverControlSystem", "Remote control and quest locks"),
    ("N-perception", NATIVE, 148739, 148920, "class TargetTrackingExtension", "Threat tracking and injection"),
    ("N-tickets", NATIVE, 150094, 150152, "func EvaluateTicketActivation", "Ticket activation and deactivation"),
    ("N-ai-condition", NATIVE, 152864, 152885, "class AICondition", "Native activation evaluation boundary"),
    ("N-ai-target", NATIVE, 156532, 156556, "func Get(", "Native target evaluation boundary"),
    ("N-ai-update", NATIVE, 288313, 288373, "func Update", "Action, animation and ticket lifecycle"),
    ("N-ai-phases", NATIVE, 288585, 288742, "func UpdateSubActions", "General/startup/loop/recovery updates"),
    ("N-ai-record", NATIVE, 289753, 289780, "class TweakAIAction", "Behavior task to TweakDB record"),
    ("N-shoot", NATIVE, 431792, 431948, "func Update", "Shoot action, tracking and cadence"),
    ("N-hit-gate", NATIVE, 164844, 164869, "func HandleBeingShot", "Time-between-hits enable gate and miss offset"),
    ("N-hit-clock", NATIVE, 165023, 165089, "func CalculateTimeBetweenHits", "Time-between-hits coefficients"),
    ("N-grenade", NATIVE, 422619, 422727, "func ThrowItem", "NPC grenade launch and slot removal"),
    ("M-durability", COMBAT + "SDPDurability.reds", 85, 184, "func Apply", "Current armor mutation and penetration"),
    ("M-armor-hook", COMBAT + "SDPDurability.reds", 187, 209, "@wrapMethod", "Armor replacement and one-shot protection"),
    ("M-armor-kit", COMBAT + "SDPArmor.reds", 59, 88, "func Covering", "Best covering piece and repair"),
    ("M-limbs", COMBAT + "CE/CE_HitZones.reds", 8, 87, "@wrapMethod", "Current pre-armor NPC limb damage hook"),
    ("M-cadence", COMBAT + "SDPCadence.reds", 14, 79, "@wrapMethod", "Weapon-derived cadence and player position read"),
    ("M-blind", COMBAT + "SDPBlindFire.reds", 27, 58, "func Observe", "Sight-derived memory and frozen blind aim"),
    ("M-suppress", COMBAT + "CE/CE_Suppression.reds", 27, 76, "func OnStim", "Player gunshot/camera-direction suppression proxy"),
    ("M-flank", COMBAT + "CE/CE_Flank.reds", 7, 44, "func OnHit", "Flank selection and live velocity read"),
    ("M-authored", COMBAT + "CE/CE_AuthoredControl.reds", 20, 50, "func GBPUnderAuthoredControl", "Quest/workspot/scene command guards"),
    ("M-chrome", COMBAT + "CE/CE_ChromeDist_Detect.reds", 1, 6, "module", "Chrome detection; distribution omitted"),
    ("M-level", SKILL + "SkillTotalLevel.reds", 17, 59, "func SDP_GetSkillRank", "Derived rank/level and XP interception"),
    ("M-milestones", SKILL + "SkillMilestones.reds", 1, 67, "module", "Existing level-15/35 milestone changes"),
    ("M-perk-compat", PERK + "ShardPerkCompatibility.reds", 1, 16, "module", "Perk activation/deactivation compatibility"),
    ("M-custom-hacks", QH + "CustomPrograms.reds", 647, 700, "@wrapMethod", "Custom menu integration and player-only execution"),
    ("M-hack-save", QH + "DesignLibrary.reds", 207, 218, "@addField", "Saved design library representation"),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    cache = {}
    sources = {}
    entries = []
    for ident, name, start, end, expected, subject in ANCHORS:
        path = ROOT / name
        if name not in cache:
            blob = path.read_bytes()
            cache[name] = blob.decode("utf-8-sig").splitlines()
            sources[name] = {"sha256": hashlib.sha256(blob).hexdigest(),
                             "bytes": len(blob), "lines": len(cache[name])}
        lines = cache[name]
        if not (1 <= start <= end <= len(lines)) or expected not in lines[start - 1]:
            raise ValueError(f"Anchor drift: {ident}: {name}:{start}: expected {expected!r}")
        entries.append({"id": ident, "file": name, "start": start, "end": end,
                        "expected": expected, "subject": subject})
    additional = [
        "final-inspect.reds",
        "SDP-Skills/r6/tweaks/SDPSkills/SkillDrivenPowerLevel.yaml",
        "SDP-Skills/r6/tweaks/SDPSkills/SkillDrivenCapacity.yaml",
        "SDP-Patches/SDP-CyberwareEx/r6/scripts/SDPCyberwareEx/CyberwareExSlots.reds",
        "SDP-Combat/r6/tweaks/SDPCombat/ChaseLimits.yaml",
        "SDP-Combat/design/SDP_COMBAT_REALISM_PASS.md",
        "SDP-Combat/design/WORLD_PROGRESSION_BACKEND.md",
        "SDP-Perks/design/WORLD_PROGRESSION_SOURCE_AUDIT.md",
        "SDP-QuickhackCrafting/design/native-dump/compression-report.json",
        "SDP-QuickhackCrafting/design/native-dump/families/overheat.json",
        "SDP-QuickhackCrafting/design/NATIVE_RECREATION.md",
    ]
    for name in additional:
        blob = (ROOT / name).read_bytes()
        sources[name] = {"sha256": hashlib.sha256(blob).hexdigest(), "bytes": len(blob),
                         "lines": len(blob.decode("utf-8-sig").splitlines())}
    manifest = {
        "research_date": "2026-10-08", "evidence": "Static source inspection; no new gameplay run",
        "installed_executable_observed": {"product_version": "2.31", "file_version": "3.0.5294808"},
        "provenance_limit": "Existing decompilation, described as 2.31 by earlier project notes; not regenerated from the executable during this research.",
        "sources": sources, "anchors": entries,
    }
    (OUT / "source-evidence.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    md = ["# Research source map", "", "Generated by `tools/research/BuildEvidenceIndex.py`.", "",
          "The IDs below anchor claims to inspected source snapshots. They prove code structure,",
          "not deployment or observed gameplay. See [research scope](README.md).", "",
          "[Machine-readable hashes and spans](source-evidence.json).", ""]
    for e in entries:
        target = (ROOT / e["file"]).as_posix() + f':{e["start"]}'
        md.extend([f'## {e["id"]}', "", f'**{e["subject"]}** — [{e["file"]}:{e["start"]}](<{target}>).', "",
                   f'Inspected span: lines {e["start"]}–{e["end"]}. Anchor: `{e["expected"]}`.', ""])
    (OUT / "SOURCE_MAP.md").write_text("\n".join(md), encoding="utf-8")
    print(f"Validated {len(entries)} anchors; fingerprinted {len(sources)} source files.")
    print("Native snapshots identical:", sources[NATIVE]["sha256"] == sources["final-inspect.reds"]["sha256"])


if __name__ == "__main__":
    main()
