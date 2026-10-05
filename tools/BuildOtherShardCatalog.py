"""Extract the fourteen proposed shard orders against the observed perk ledger.

This produces a reviewable catalog. Unknown packages stay explicit rather than
being silently treated as working gameplay effects.
"""

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ORDER = ROOT / "design/SHARD_GRADE_ORDERS.md"
LEDGER = ROOT / "design/perk-ledger.csv"
OUTPUT = ROOT / "design/other-shard-catalog.json"
GRADES = ["Tier 1", "Tier 1+", "Tier 2", "Tier 2+", "Tier 3", "Tier 3+", "Tier 4", "Tier 4+", "Tier 5", "Tier 5+", "Tier 5++"]
FAMILIES = ["Adrenaline", "Obliteration", "Quake", "Air Dash", "Sharpshooter", "Blade Runner", "Chrome", "Pyromania", "Bolt", "Overclock", "Hack Queue", "Smart Lock", "Ninjutsu", "Juggler"]


def effect_phrase(text: str) -> str:
    if text.startswith(("Finisher: ", "Warning: ")):
        return text.rsplit(": ", 1)[0]
    return text.split(": ", 1)[0]


def main() -> None:
    rows = list(csv.DictReader(LEDGER.open(encoding="utf-8")))
    by_family = {family: [r for r in rows if r["family"] == family] for family in FAMILIES}
    catalog: dict[str, dict] = {}
    family = ""
    for line in ORDER.read_text(encoding="utf-8").splitlines():
        if line.startswith("### "):
            family = line[4:].strip()
            if family in FAMILIES:
                catalog[family] = {"grades": []}
        match = re.match(r"^\| (Tier [^|]+) \| (.+) \|$", line)
        if not match or family not in catalog or match.group(1) not in GRADES:
            continue
        grade_name, description = match.groups()
        phrase = effect_phrase(description)
        if "**Custom:**" in description:
            catalog[family]["grades"].append({
                "grade": grade_name, "description": description,
                "effects": [], "custom": True, "unparsed": "",
            })
            continue
        candidates = []
        for perk in by_family[family]:
            name = perk["display_name"]
            pattern = rf"(?<![A-Za-z]){re.escape(name)}(?![A-Za-z])"
            for occurrence in re.finditer(pattern, phrase, re.IGNORECASE):
                candidates.append((occurrence.start(), occurrence.end(), perk))
        candidates.sort(key=lambda item: (-(item[1] - item[0]), item[0]))
        chosen = []
        occupied = set()
        for start, end, perk in candidates:
            if any(pos in occupied for pos in range(start, end)):
                continue
            occupied.update(range(start, end))
            chosen.append((start, end, perk))
        chosen.sort(key=lambda item: item[0])
        effects = []
        for start, end, perk in chosen:
            tail = phrase[end:]
            rank_match = re.match(r"\s+([123])(?:\s*\+\s*([123]))?\b", tail)
            ranks = [int(rank_match.group(1))] if rank_match else [1]
            if rank_match and rank_match.group(2):
                ranks.append(int(rank_match.group(2)))
            packages = perk["level_packages"].split(";")
            for rank in ranks:
                package = packages[rank - 1] if rank <= len(packages) else "?"
                effects.append({"perk": perk["record_id"], "rank": rank, "package": package})
        unparsed = "".join(char if index not in occupied else " " for index, char in enumerate(phrase))
        unparsed = re.sub(r"\b[123]\b|\+|\*|\s|[!.:,;'-]", "", unparsed)
        catalog[family]["grades"].append({
            "grade": grade_name,
            "description": description,
            "effects": effects,
            "unparsed": unparsed,
        })
    OUTPUT.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    for family in FAMILIES:
        grades = catalog.get(family, {}).get("grades", [])
        issues = [(g["grade"], g["unparsed"]) for g in grades if g["unparsed"]]
        unknown = [(g["grade"], e["perk"], e["rank"]) for g in grades for e in g["effects"] if e["package"] == "?"]
        print(f"{family}: {len(grades)} grades, {sum(len(g['effects']) for g in grades)} effects, unparsed={issues}, unknown={unknown}")
    print(OUTPUT)


if __name__ == "__main__":
    main()
