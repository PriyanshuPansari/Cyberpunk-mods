"""Build readable names for the live shard XP overlay from the training catalog."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / "design" / "shard-training.json").read_text(encoding="utf-8"))
lines = [
    "// Generated from design/shard-training.json. Run tools/GenerateShardTrainingLabels.py after editing it.",
    "module SkillDrivenProgression",
    "",
    "public func SDP_TrainingFamilySourceName(family: Int32, source: Int32) -> String {",
]
for family in catalog["families"]:
    for source in family["sources"]:
        name = source["text"].replace("\\", "\\\\").replace('"', '\\"')
        lines.append(f'  if family == {family["id"]} && source == {source["id"]} {{ return "{name}"; }};')
lines += ['  return "unknown action";', '}', '']
path = root / "r6" / "scripts" / "SkillDrivenProgression" / "ShardTrainingLabels.generated.reds"
path.write_text("\n".join(lines), encoding="utf-8")
