"""Generate readable recorded-effect names and descriptions for the character ledger."""

import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / "design/other-shard-catalog.json").read_text(encoding="utf-8"))
training = json.loads((root / "design/shard-training.json").read_text(encoding="utf-8"))
deadeye = training["deadeye"]["effects"]
expansions = json.loads((root / "design/expansion-shards.json").read_text(encoding="utf-8"))["shards"]


def quote(value: str) -> str:
    return json.dumps(re.sub(r"\*\*", "", value), ensure_ascii=False)


lines = [
    "// Generated from design/other-shard-catalog.json and design/shard-training.json.",
    "module SkillDrivenProgression",
    "",
    "public func SDP_RecordedEffectTitle(family: Int32, grade: Int32) -> String {",
]
for grade, description in enumerate(deadeye, 1):
    titles = " + ".join(
        part.split(":", 1)[0].strip()
        for part in description.split(";") if ":" in part
    )
    lines.append(f"  if family == 0 && grade == {grade} {{ return {quote(titles)}; }};")
for family_id, (_, family) in enumerate(catalog.items(), 1):
    for grade, entry in enumerate(family["grades"], 1):
        title = entry["description"].split(":", 1)[0].strip()
        lines.append(f"  if family == {family_id} && grade == {grade} {{ return {quote(title)}; }};")
lines += [
    '  if family == 15 && grade == 1 { return "Road Warrior + Fury Road + Stuntjock + Carhacker + Gearhead"; };',
] + [
    f'  if family == {x["family"]} && grade == 1 {{ return {quote(x["name"] + " slots")}; }};' for x in expansions
] + [
    '  return "Unknown effect";',
    "}",
    "",
    "public func SDP_RecordedEffectDescription(family: Int32, grade: Int32) -> String {",
]
for grade, description in enumerate(deadeye, 1):
    lines.append(f"  if family == 0 && grade == {grade} {{ return {quote(description)}; }};")
for family_id, (_, family) in enumerate(catalog.items(), 1):
    for grade, entry in enumerate(family["grades"], 1):
        lines.append(
            f"  if family == {family_id} && grade == {grade} "
            f"{{ return {quote(entry['description'])}; }};"
        )
lines += [
    '  if family == 15 && grade == 1 { return "Road Warrior, Fury Road, Stuntjock, Carhacker, and Gearhead vehicle perks."; };',
] + [
    f'  if family == {x["family"]} && grade == 1 {{ return {quote(str(x["slots"]) + " extra " + x["name"].replace(" Expansion", "") + " cyberware slot(s) (Cyberware-EX)")}; }};' for x in expansions
] + [
    '  return "Unknown effect";',
    "}",
]
(root / "r6/scripts/SkillDrivenProgression/ShardRecordedLedger.generated.reds").write_text(
    "\n".join(lines) + "\n", encoding="utf-8"
)
