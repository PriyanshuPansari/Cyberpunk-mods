"""Build the design ledger from CET perk/package logs and a decompiled script dump.

The inputs are observations from the installed game, not generated mod data.
This tool does not change game files.
"""

import argparse
import csv
import re
from pathlib import Path


FAMILIES = {
    "Body": ("Adrenaline", "Obliteration", "Quake"),
    "Reflexes": ("Air Dash", "Sharpshooter", "Blade Runner"),
    "Tech": ("Chrome", "Pyromania", "Bolt"),
    "Intelligence": ("Overclock", "Hack Queue", "Smart Lock"),
    "Cool": ("Ninjutsu", "Deadeye", "Juggler"),
}
SKILLS = {
    "Body": "Solo",
    "Reflexes": "Shinobi",
    "Tech": "Engineer",
    "Intelligence": "Netrunner",
    "Cool": "Headhunter",
}
BRANCH_INDEX = {"Central": 0, "Left": 1, "Right": 2}
SPECIAL = {
    "Body_Right_Milestone_1": "Vehicle",
    "Cool_Left_Milestone_1": "Vehicle",
    "Body_Inbetween_Left_3": "Adrenaline",
    "Body_Inbetween_Right_3": "Quake",
    "Body_Master_Perk_1": "Obliteration",
    "Body_Master_Perk_2": "Obliteration",
    "Body_Master_Perk_3": "Adrenaline",
    "Body_Master_Perk_5": "Quake",
    "Reflexes_Inbetween_Left_3": "Sharpshooter",
    "Reflexes_Inbetween_Right_2": "Blade Runner",
    "Reflexes_Master_Perk_1": "Sharpshooter",
    "Reflexes_Master_Perk_2": "Sharpshooter",
    "Reflexes_Master_Perk_3": "Air Dash",
    "Reflexes_Master_Perk_5": "Blade Runner",
    "Tech_Inbetween_Left_3": "Pyromania",
    "Tech_Inbetween_Right_2": "Chrome",
    "Tech_Master_Perk_2": "Pyromania",
    "Tech_Master_Perk_3": "Chrome",
    "Tech_Master_Perk_5": "Bolt",
    "Intelligence_Inbetween_Left_2": "Hack Queue",
    "Intelligence_Inbetween_Left_3": "Overclock",
    "Intelligence_Inbetween_Right_2": "Smart Lock",
    "Intelligence_Right_Milestone_1": "Hack Queue",
    "Intelligence_Master_Perk_1": "Hack Queue",
    "Intelligence_Master_Perk_3": "Overclock",
    "Intelligence_Master_Perk_4": "Smart Lock",
    "Cool_Inbetween_Left_2": "Deadeye",
    "Cool_Inbetween_Left_3": "Ninjutsu",
    "Cool_Inbetween_Right_3": "Juggler",
    "Cool_Master_Perk_1": "Deadeye",
    "Cool_Master_Perk_2": "Deadeye",
    "Cool_Master_Perk_4": "Juggler",
    "Intelligence_Right_Milestone_1": "Vehicle",
    "Reflexes_Left_Milestone_1": "Vehicle",
    "Tech_Right_Milestone_1": "Vehicle",
}
ANCHORS = {
    "Body_Central_Milestone_3",
    "Body_Left_Milestone_3",
    "Body_Right_Milestone_3",
    "Reflexes_Central_Milestone_3",
    "Reflexes_Left_Milestone_3",
    "Reflexes_Right_Milestone_3",
    "Tech_Central_Milestone_3",
    "Tech_Left_Milestone_3",
    "Tech_Right_Milestone_3",
    "Intelligence_Central_Milestone_3",
    "Intelligence_Left_Milestone_2",
    "Intelligence_Right_Milestone_2",
    "Cool_Central_Milestone_3",
    "Cool_Left_Milestone_3",
    "Cool_Right_Milestone_2",
}
VEHICLE = {
    "Body_Right_Milestone_1",
    "Reflexes_Left_Milestone_1",
    "Intelligence_Right_Milestone_1",
    "Cool_Left_Milestone_1",
    "Tech_Right_Milestone_1",
}
EXCLUDE = {"Cool_Right_Perk_3_3"}
INTERNAL_REVIEW = {"Intelligence_Left_Perk_3_1"}
NAME_PATTERN = re.compile(
    r"\] SDPPERK (NewPerks\.[^ ]+) \| (.*?) \| (.*?) \| lv=(\d+)"
)
PACKAGE_PATTERN = re.compile(r"\] SDPPKG (NewPerks\.[^ ]+) \| (.*)")
SCRIPT_CHECK = "IsNewPerkBought(gamedataNewPerkType.{suffix})"


def family_for(suffix: str) -> str:
    skill_tree, branch, _ = suffix.split("_", 2)
    if suffix in SPECIAL:
        return SPECIAL[suffix]
    if branch in BRANCH_INDEX:
        return FAMILIES[skill_tree][BRANCH_INDEX[branch]]
    raise ValueError(f"No family assignment for {suffix}")


def role_for(suffix: str) -> str:
    if suffix in EXCLUDE:
        return "obsolete_exclude"
    if suffix in INTERNAL_REVIEW:
        return "internal_review"
    if suffix in VEHICLE:
        return "vehicle_side"
    if suffix in ANCHORS:
        return "anchor_candidate"
    if "_Master_" in suffix:
        return "capstone_candidate"
    if "_Inbetween_" in suffix:
        return "bridge_candidate"
    if "_Milestone_" in suffix:
        return "milestone_support"
    return "side_perk_candidate"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--scripts", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("design/perk-ledger.csv"))
    args = parser.parse_args()

    names = {}
    packages = {}
    for line in args.log.read_text(encoding="utf-8", errors="replace").splitlines():
        match = NAME_PATTERN.search(line)
        if match and not match.group(1).startswith("NewPerks.Espionage_"):
            names[match.group(1)] = (match.group(2).strip(), int(match.group(4)))
        match = PACKAGE_PATTERN.search(line)
        if match and not match.group(1).startswith("NewPerks.Espionage_"):
            packages[match.group(1)] = match.group(2).split(",")
    if len(names) != 180 or len(packages) != 180 or names.keys() != packages.keys():
        raise ValueError(f"Expected matching 180-record snapshots; names={len(names)} packages={len(packages)}")

    scripts = args.scripts.read_text(encoding="utf-8", errors="replace")
    rows = []
    for record_id in sorted(names):
        suffix = record_id.removeprefix("NewPerks.")
        tree = suffix.split("_", 1)[0]
        name, levels = names[record_id]
        record_packages = packages[record_id]
        if len(record_packages) != levels:
            raise ValueError(f"Level/package mismatch: {record_id}")
        role = role_for(suffix)
        rows.append(
            {
                "record_id": record_id,
                "display_name": name,
                "linked_skill": SKILLS[tree],
                "family": family_for(suffix),
                "role": role,
                "vanilla_levels": levels,
                "level_packages": ";".join(record_packages),
                "direct_script_checks": scripts.count(SCRIPT_CHECK.format(suffix=suffix)),
                "effect_audit": "exclude" if role == "obsolete_exclude" else "pending",
            }
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"{args.output}: {len(rows)} non-Relic records, {len(set(row['family'] for row in rows))} families")


if __name__ == "__main__":
    main()
