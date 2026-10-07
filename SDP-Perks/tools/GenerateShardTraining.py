"""Generate the XP award table used by redscript from the reviewed training catalog."""

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
training = json.loads((root / "design/shard-training.json").read_text(encoding="utf-8"))
lines = [
    "// Generated from design/shard-training.json. Edit that file to retune awards.",
    "module SkillDrivenProgression",
    "",
    "public func SDP_TrainingThreshold(grade: Int32) -> Int32 {",
]
for grade, actions in enumerate(training["targetActions"], 1):
    lines.append(
        f'  if grade == {grade} {{ return {actions * training["xpPerNewAction"]}; }};'
    )
lines += ["  return 0;", "}", "", "public func SDP_TrainingFamilyThreshold(family: Int32, grade: Int32) -> Int32 {"]
lines += [
    "  if family < 1 || family > 15 { return 0; };",
    "  if family == 15 && grade != 1 { return 0; };",
]
for family in training["families"]:
    for grade, actions in enumerate(training["targetActions"], 1):
        if family["id"] == 15 and grade != 1:
            break
        has_new = any(source["grade"] == grade for source in family["sources"])
        if not has_new:
            lines.append(
                f'  if family == {family["id"]} && grade == {grade} '
                f'{{ return {actions * training["xpPerPriorAction"]}; }};'
            )
lines += [
    "  return SDP_TrainingThreshold(grade);",
    "}", "", "public func SDP_TrainingDeadeyeSourceGrade(source: Int32) -> Int32 {",
]
for source in training["deadeye"]["sources"]:
    lines.append(f'  if source == {source["id"]} {{ return {source["grade"]}; }};')
lines += ["  return 0;", "}", "", "public func SDP_TrainingDeadeyeAward(source: Int32, grade: Int32) -> Int32 {"]
for source in training["deadeye"]["sources"]:
    lines.append(
        f'  if source == {source["id"]} && grade >= {source["grade"]} '
        f'{{ return grade == {source["grade"]} ? {training["xpPerNewAction"]} '
        f': {training["xpPerPriorAction"]}; }};'
    )
lines += ["  return 0;", "}", "", "public func SDP_TrainingFamilyAward(family: Int32, source: Int32, grade: Int32) -> Int32 {"]
for family in training["families"]:
    for source in family["sources"]:
        lines.append(
            f'  if family == {family["id"]} && source == {source["id"]} '
            f'&& grade >= {source["grade"]} '
            f'{{ return grade == {source["grade"]} ? {training["xpPerNewAction"]} '
            f': {training["xpPerPriorAction"]}; }};'
        )
lines += ["  return 0;", "}", "", "public func SDP_TrainingFamilySourceGrade(family: Int32, source: Int32) -> Int32 {"]
for family in training["families"]:
    for source in family["sources"]:
        lines.append(
            f'  if family == {family["id"]} && source == {source["id"]} '
            f'{{ return {source["grade"]}; }};'
        )
lines += ["  return 0;", "}"]
(root / "r6/scripts/SkillDrivenProgression/ShardTraining.generated.reds").write_text(
    "\n".join(lines) + "\n", encoding="utf-8"
)
