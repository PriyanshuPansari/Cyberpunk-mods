"""Create ArchiveXL English strings for the neural processor and shards."""

import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
training = json.loads((root / "design/shard-training.json").read_text(encoding="utf-8"))
source = root / "source/skilldrivenprogression/localization/en-us/attunements.json.json"
output = source.with_name("processor.json.json")
resource = json.loads(source.read_text(encoding="utf-8"))
resource["Header"]["ArchiveFileName"] = (
    "skilldrivenprogression\\localization\\en-us\\processor.json"
)
strings = {
    "sdp_neural_processor_name": "Neural Processor",
    "sdp_neural_processor_description": (
        "Starter processor with three training-shard bays and a dedicated Relic bay. "
        "Training progress belongs to the user; recorded effects remain active "
        "after removal."
    ),
    "sdp_deadeye_tier1_name": "Retired Deadeye Shard",
    "sdp_deadeye_tier1_description": (
        "Legacy item. Load your save to convert it to the current Deadeye chain."
    ),
    "sdp_deadeye_tier1_training": (
        "Retired prototype. Its character-owned progress converts on save load."
    ),
    "sdp_deadeye_tier1plus_name": "Retired Deadeye Shard Tier 1+",
    "sdp_deadeye_tier1plus_description": (
        "Legacy item. Load your save to convert it to the current Deadeye chain."
    ),
    "sdp_deadeye_tier1plus_training": (
        "Retired prototype. Its character-owned progress converts on save load."
    ),
    "sdp_deadeye_focus_tier1_name": "Deadeye Shard Tier 1: Focus",
    "sdp_deadeye_focus_tier1_description": (
        "New effect: Focus. Aim at full Stamina with a pistol, revolver, precision "
        "rifle, or sniper rifle to enter Focus; shots during Focus cost no Stamina."
    ),
    "sdp_deadeye_focus_tier1plus_name": "Deadeye Shard Tier 1+: Focus Precision",
    "sdp_deadeye_focus_tier1plus_description": (
        "New effects: Focus precision bonus increases headshot and weakspot damage. "
        "Rinse and Reload speeds up reloads after aimed neutralizations."
    ),
    "sdp_deadeye_focus_tier2_name": "Deadeye Shard Tier 2: Deep Breath",
    "sdp_deadeye_focus_tier2_description": (
        "New effects: Deep Breath slows time during Focus. No Sweat reduces "
        "Focus's ending Stamina cost after neutralizations."
    ),
    "sdp_cigarette_yeheyuan_name": "Yeheyuan Cigarette",
    "sdp_cigarette_yeheyuan_description": (
        "Restores Nerve when smoked. Cannot be used in combat."
    ),
    "sdp_cigarette_morley_name": "Morley Cigarette",
    "sdp_cigarette_morley_description": (
        "Restores Nerve when smoked. Cannot be used in combat."
    ),
    "sdp_composure_name": "Composure",
    "sdp_composure_description": (
        "A cigarette steadies you. +10% skill XP, and 15% less weapon recoil and spread."
    ),
    "sdp_relic_module_name": "Relic",
    "sdp_relic_module_description": (
        "The Relic is housed in the neural processor's dedicated bay. "
        "Its story and Relic abilities continue to work as usual."
    ),
}
later_grades = [
    ("tier2plus", "Tier 2+: Head to Head", "Head to Head and Pull!", "neutralizations during Focus and airborne grenade shots during Focus", 2500),
    ("tier3", "Tier 3: Deadeye", "Deadeye mode", "damaging precision-weapon hits during Deadeye", 3000),
    ("tier3plus", "Tier 3+: Long Shot", "Deadeye precision damage and Long Shot", "long-range precision hits during Deadeye", 3500),
    ("tier4", "Tier 4: Quick Draw", "Quick Draw and California Reaper", "combat weapon swaps and precision neutralizations during Deadeye", 4000),
    ("tier4plus", "Tier 4+: High Noon", "High Noon", "reloads after a precision neutralization during Deadeye", 4500),
    ("tier5", "Tier 5: Deadeye Efficiency", "reduced shooting Stamina cost during Deadeye", "damaging precision-weapon hits during Deadeye", 5000),
    ("tier5plus", "Tier 5+: Run 'N' Gun", "Run 'N' Gun", "damaging hip-fire hits", 5500),
    ("tier5plusplus", "Tier 5++: Nerves of Tungsten-Steel", "Nerves of Tungsten-Steel", "critical precision hits during Deadeye", 6000),
]
for suffix, title, effects, use_source, threshold in later_grades:
    strings[f"sdp_deadeye_focus_{suffix}_name"] = f"Deadeye Shard {title}"
    strings[f"sdp_deadeye_focus_{suffix}_description"] = (
        f"New effects: {effects}. Record this grade to keep them active after removing the shard."
    )

deadeye_suffixes = [
    "tier1", "tier1plus", "tier2", "tier2plus", "tier3", "tier3plus",
    "tier4", "tier4plus", "tier5", "tier5plus", "tier5plusplus",
]


channels = json.loads((root / "design/shard-channels.json").read_text(encoding="utf-8"))


def channel_text(shard: str, grade: int) -> str:
    """Training v2 tooltip: what trains the shard at this grade, and the cap."""
    items = [text for unlock, text in channels["channels"][shard] if unlock <= grade]
    threshold = (channels["vehicleThreshold"] if shard == "Vehicle"
                 else channels["expansionThreshold"] if shard.endswith("Expansion")
                 else channels["thresholds"][grade - 1])
    return (f"Trains from: {'; '.join(items)}. XP scales with enemy level and rarity and with your level. "
            f"Record at {threshold} XP.")


def training_text(sources: list[dict], grade: int, threshold: int) -> str:
    active = [source for source in sources if source["grade"] <= grade]
    awards = "; ".join(
        f'+{(training["xpPerNewAction"] if source["grade"] == grade else training["xpPerPriorAction"])} '
        f'{source["text"]}'
        for source in active
    )
    carry_text = " Earlier-grade actions give half XP." if grade > 1 else ""
    return f"Training actions (one award per event): {awards}.{carry_text} Record at {threshold} XP."


for grade, suffix in enumerate(deadeye_suffixes, 1):
    strings[f"sdp_deadeye_focus_{suffix}_description"] = (
        f"New effects: {training['deadeye']['effects'][grade - 1]}."
    )
    strings[f"sdp_deadeye_focus_{suffix}_training"] = channel_text("Deadeye", grade)
other_catalog = json.loads((root / "design/other-shard-catalog.json").read_text(encoding="utf-8"))
for family, rules in zip(other_catalog, training["families"]):
    assert family == rules["name"]
    family_key = family.replace(" ", "").lower()
    for grade_index, grade in enumerate(other_catalog[family]["grades"], 1):
        grade_key = grade["grade"].replace(" ", "").replace("+", "plus").lower()
        prefix = f"sdp_{family_key}_{grade_key}"
        effect_text = re.sub(r"\*\*", "", grade["description"])
        has_new = any(source["grade"] == grade_index for source in rules["sources"])
        award = training["xpPerNewAction"] if has_new else training["xpPerPriorAction"]
        threshold = training["targetActions"][grade_index - 1] * award
        strings[f"{prefix}_name"] = f"{family} Shard {grade['grade']}"
        strings[f"{prefix}_description"] = f"New effects: {effect_text}"
        strings[f"{prefix}_training"] = channel_text(family, grade_index)
strings["sdp_vehiclechip_name"] = "Vehicle Shard"
strings["sdp_vehiclechip_description"] = (
    "New effects: Road Warrior, Fury Road, Stuntjock, Carhacker, and Gearhead. "
    "Record this chip to keep its effects without the processor."
)
strings["sdp_vehiclechip_training"] = channel_text("Vehicle", 1)
expansions = json.loads((root / "design/expansion-shards.json").read_text(encoding="utf-8"))["shards"]
for x in expansions:
    k = x["name"].replace(" ", "").lower() + "chip"
    slots = "one extra slot" if x["slots"] == 1 else f"{x['slots']} extra slots"
    system = x["name"].replace(" Expansion", "")
    extra = " Also counts as Ambidextrous (the extra Hands slot)." if x["family"] == 22 else ""
    strings[f"sdp_{k}_name"] = f"{x['name']} Shard"
    strings[f"sdp_{k}_description"] = (
        f"New effects: unlocks {slots} for {system} cyberware (Cyberware-EX).{extra} "
        "Works while slotted; record it to keep the slots without the processor."
    )
    strings[f"sdp_{k}_training"] = channel_text(x["name"], 1)
resource["Data"]["RootChunk"]["root"]["Data"]["entries"] = [
    {
        "$type": "localizationPersistenceOnScreenEntry",
        "femaleVariant": value,
        "maleVariant": "",
        "primaryKey": "0",
        "secondaryKey": key,
    }
    for key, value in strings.items()
]
output.write_text(json.dumps(resource, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(output)
