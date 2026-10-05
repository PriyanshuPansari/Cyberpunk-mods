"""Build English cyberware attunement text from a WolvenKit onscreens export.

Usage: python tools/GenerateAttunementText.py path/to/onscreens.json.json
The input is a JSON conversion of the installed game's English onscreens.json.
"""

import copy
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "source" / "skilldrivenprogression" / "localization" / "en-us" / "attunements.json.json"
PREFIX = "Gameplay-Cyberware-Attunement-"
SKILLS = {
    "Body": ("Solo", "Body"),
    "Cool": ("Headhunter", "Cool"),
    "Intelligence": ("Netrunner", "Intelligence"),
    "Reflexes": ("Shinobi", "Reflexes"),
    "TechnicalAbility": ("Engineer", "Technical Ability"),
}


def linked_skill(key):
    suffix = key.removeprefix(PREFIX)
    if suffix.startswith("Body"):
        return SKILLS["Body"]
    if suffix.startswith("Cool"):
        return SKILLS["Cool"]
    if suffix.startswith("Intelligence"):
        return SKILLS["Intelligence"]
    if suffix.startswith("Reflex"):
        return SKILLS["Reflexes"]
    if suffix.startswith("TechnicalAbility") or suffix.startswith("Tech"):
        return SKILLS["TechnicalAbility"]
    raise ValueError(f"Unknown attunement: {key}")


def effect_label(text):
    first_line = text.split(r"\nCurrent total:", 1)[0]
    plain = re.sub(r"<[^>]+>", "", first_line)
    plain = re.sub(r"^[+-]\{float_0\}(?:%| sec\.)?\s*", "", plain)
    plain = plain.removesuffix(" per Attribute Point.")
    plain = plain.replace(" with this cyberware", "")
    plain = plain.replace(" for this cyberware", "")
    plain = plain.removeprefix("to ")
    special = {"all Stamina costs": "Stamina cost reduction"}
    plain = special.get(plain, plain)
    return plain[0].upper() + plain[1:]


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    with open(sys.argv[1], encoding="utf-8") as source:
        original = json.load(source)

    entries = original["Data"]["RootChunk"]["root"]["Data"]["entries"]
    updated = []
    for entry in entries:
        key = entry.get("secondaryKey", "")
        if not key.startswith(PREFIX) or entry["femaleVariant"] == "!OBSOLETE":
            continue

        skill, _ = linked_skill(key)
        text = entry["femaleVariant"]
        if key.endswith("Name"):
            text = f"{skill} Attuned"
        elif key.endswith("TechMasterCyberware"):
            text = text.replace("For each Attribute Point:", "Scales with each Engineer level:")
            text = re.sub(r"[+]\{float_[0-3]\}%\s*", "", text)
        else:
            if r"\nCurrent total:" not in text or "per Attribute Point" not in text:
                raise ValueError(f"No attribute wording in {key}: {text}")
            total = text.split(r"\nCurrent total:", 1)[1]
            highlight = '<Rich color="TooltipText.cyberwareDescriptionHighlightColor" style="Semi-Bold">'
            text = (
                f"{highlight}{effect_label(text)}</> scales with each {skill} level."
                rf"\nCurrent total:{total}"
            )

        if "Attribute" in text or "attribute" in text:
            raise ValueError(f"Attribute wording remains in {key}: {text}")

        item = copy.deepcopy(entry)
        item["femaleVariant"] = text
        updated.append(item)

    if len(updated) != 41:
        raise ValueError(f"Expected 41 active vanilla attunement strings, found {len(updated)}")

    output = copy.deepcopy(original)
    output["Data"]["RootChunk"]["root"]["Data"]["entries"] = updated
    output["Header"]["ArchiveFileName"] = (
        "skilldrivenprogression\\localization\\en-us\\attunements.json"
    )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "w", encoding="utf-8") as destination:
        json.dump(output, destination, ensure_ascii=False, indent=2)
        destination.write("\n")
    print(f"Wrote {len(updated)} attunement strings to {OUTPUT}")


if __name__ == "__main__":
    main()
