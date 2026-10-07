"""Cross-check independent progression inputs and generated/documented outputs.

Run from any directory with Python 3. This does not execute the game runtime;
docs/REGRESSION_CHECKS.md contains the required in-game acceptance cases.
"""
import os
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "r6/scripts/SkillDrivenProgression"
TWEAKS = ROOT / "r6/tweaks/SkillDrivenProgression"


def read(path):
    return path.read_text(encoding="utf-8")


def verify_packages():
    # Derive expected provenance from the deployable TweakXL records, not from
    # the generator's Python mapping. Missing source IDs cause duplicate perks.
    expected = {}
    for name in ("ShardPackages.generated.yaml", "PerkPrototype.yaml"):
        expected.update(re.findall(
            r"^(SkillDrivenProgression\.\w+):\s*\n  \$base: (NewPerks\.\w+)",
            read(TWEAKS / name), re.M))
    generated = dict(re.findall(
        r'if Equals\(packageID, t"([^"]+)"\) \{ return t"([^"]+)"; \}',
        read(SCRIPTS / "ShardPackageSources.generated.reds")))
    assert expected and generated == expected, "Clone provenance is stale or incomplete"
    catalog = json.loads(read(ROOT / "design/other-shard-catalog.json"))
    for family, entry in catalog.items():
        for grade, row in enumerate(entry["grades"], 1):
            for effect, rank in enumerate(row["effects"], 1):
                if rank["package"] != "?":
                    key = f"SkillDrivenProgression.SDP{family.replace(' ', '')}G{grade}E{effect}"
                    assert expected.get(key) == rank["package"], key
    # Catch accidental reintroduction of a fabricated GLP for this scripted rank.
    chrome = catalog["Chrome"]["grades"][4]["effects"][0]
    assert chrome["rank"] == 3 and chrome["package"] == "?"
    assert (SCRIPTS / "ShardChrome.reds").is_file()
    print(f"PASS: {len(expected)} private package sources match deployable records/catalog")


def verify_thresholds():
    channels = json.loads(read(ROOT / "design/shard-channels.json"))
    source = read(SCRIPTS / "ShardChannels.reds")
    body = source.split("public func SDP_ChannelThreshold", 1)[1].split("// Channel ids", 1)[0]
    actual = {int(g): int(xp) for g, xp in re.findall(r"if grade == (\d+) \{ return (\d+);", body)}
    assert actual == dict(enumerate(channels["thresholds"], 1)), "Runtime/JSON threshold mismatch"
    # Vehicle now shares its one-grade branch with Expansion families (>= 15).
    vehicle = re.search(r"family\s*(?:==|>=)\s*15.*?grade == 1 \? (\d+)", body)
    assert vehicle is not None, "Missing Vehicle/Expansion threshold branch"
    assert int(vehicle[1]) == channels["vehicleThreshold"]
    rows = re.findall(r"^\| (\d+) \| [^|]+ \| (\d+) \|$", read(ROOT / "README.md"), re.M)
    assert {int(g): int(xp) for g, xp in rows} == actual, "README thresholds are stale"
    localized = read(ROOT / "source/skilldrivenprogression/localization/en-us/processor.json.json")
    for xp in set(channels["thresholds"]) | {channels["vehicleThreshold"]}:
        assert f"Record at {xp} XP." in localized, f"Missing tooltip threshold {xp}"
    print("PASS: runtime, JSON, README and localization thresholds agree")


def verify_balance():
    text = read(ROOT / "design/SPECIALIST_BALANCE.md")
    count = 0
    for skills, current, highest, top_two, weighted in re.findall(
        r"^\| ([\d, ]+) \| (\d+) \| (\d+) \| (\d+) \| (\d+) \|$", text, re.M):
        levels = sorted(map(int, skills.split(",")), reverse=True)
        a, b, c = levels[:3]
        expected = [sum(levels) // 5, a, (a + b) // 2, (7 * a + 2 * b + c) // 10]
        assert list(map(int, (current, highest, top_two, weighted))) == expected, levels
        count += 1
    assert count == 9
    # All skill values at both endpoints, and monotonicity over permutations
    # of representative specialist/hybrid/broad distributions.
    import itertools
    for levels in itertools.product((1, 10, 30, 59, 60), repeat=5):
        def power(values):
            a, b, c = sorted(values, reverse=True)[:3]
            return (7 * a + 2 * b + c) / 10
        before = power(levels)
        assert 1 <= before <= 60
        for i, level in enumerate(levels):
            if level < 60:
                after = list(levels)
                after[i] += 1
                assert power(after) >= before
    print(f"PASS: {count} historical comparison rows and archived weighted-formula bounds/monotonicity")


def verify_links():
    paths = [ROOT / name for name in (
        "README.md", "ALL_SHARDS.md", "PERK_SHARDS.md", "TRAINING_METHODS.md", "CET_DEADEYE_COMMANDS.md",
        "design/SPECIALIST_BALANCE.md", "design/SHARD_TRAINING_V2.md",
        "design/WORLD_PROGRESSION_PLAN.md", "design/WORLD_PROGRESSION_MOD_RESEARCH.md",
        "design/WORLD_PROGRESSION_LITE.md", "design/WORLD_PROGRESSION_SOURCE_AUDIT.md",
        "design/COMBAT_OVERHAUL_COMPARISON.md",
        "design/WORLD_PROGRESSION_BACKEND.md",
        "docs/history/WORLD_PROGRESSION_LITE_INITIAL.md",
        "design/SHARD_XP_MODEL.md", "docs/REGRESSION_CHECKS.md",
        "docs/history/PERK_SHARDS_V1.md", "docs/history/SHARD_TRAINING_V2_DRAFT.md")]
    # Since the SDP split some documents and link targets live in the sibling repos (../SDP-*).
    siblings = sorted(ROOT.parent.glob("SDP-*"))
    def exists_anywhere(target):
        if target.exists():
            return True
        rel = os.path.relpath(target, ROOT)
        return any((repo / rel).exists() or any((sub / rel).exists() for sub in repo.glob("SDP-*")) for repo in siblings)
    for path in paths:
        if not path.exists():
            continue
        for link in re.findall(r"\[[^\]]*\]\(([^)]+)\)", read(path)):
            if "://" in link or link.startswith("#"):
                continue
            assert exists_anywhere(path.parent / link.split("#")[0]), f"Broken link: {path.name}: {link}"
    print("PASS: consolidated documentation links resolve")


if __name__ == "__main__":
    verify_packages()
    verify_thresholds()
    verify_balance()
    verify_links()
