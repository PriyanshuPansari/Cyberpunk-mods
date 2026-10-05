"""Generate physical shard records and a redscript catalog from reviewed orders."""

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / "design/other-shard-catalog.json").read_text(encoding="utf-8"))
LEDGER = {r["record_id"]: r for r in csv.DictReader((ROOT / "design/perk-ledger.csv").open(encoding="utf-8"))}
FAMILIES = list(CATALOG)
QUALITY = ["Common", "CommonPlus", "Uncommon", "UncommonPlus", "Rare", "RarePlus", "Epic", "EpicPlus", "Legendary", "LegendaryPlus", "LegendaryPlusPlus"]
SUFFIX = ["Tier1", "Tier1Plus", "Tier2", "Tier2Plus", "Tier3", "Tier3Plus", "Tier4", "Tier4Plus", "Tier5", "Tier5Plus", "Tier5PlusPlus"]
PROFICIENCY = {"Solo": "StrengthSkill", "Shinobi": "ReflexesSkill", "Engineer": "TechnicalAbilitySkill", "Netrunner": "IntelligenceSkill", "Headhunter": "CoolSkill"}
VEHICLE = [r for r in LEDGER.values() if r["family"] == "Vehicle"]
# Standalone Cyberware-EX slot shards, families 16-23 (design/expansion-shards.json).
EXPANSIONS = json.loads((ROOT / "design/expansion-shards.json").read_text(encoding="utf-8"))["shards"]


def key(family: str) -> str:
    return family.replace(" ", "")


def item(family: str, grade: int) -> str:
    return f"SkillDrivenProgression.{key(family)}{SUFFIX[grade - 1]}Shard"


def loc(family: str, grade: int, kind: str) -> str:
    return f"sdp_{key(family).lower()}_{SUFFIX[grade - 1].lower()}_{kind}"


def chip(shard: dict) -> str:
    return f"SkillDrivenProgression.{key(shard['name'])}Chip"


def chip_loc(shard: dict, kind: str) -> str:
    return f"sdp_{key(shard['name']).lower()}chip_{kind}"


def package(family: str, grade: int, effect: int) -> str:
    return f"SkillDrivenProgression.SDP{key(family)}G{grade}E{effect}"


def generate_tweaks() -> None:
    lines = ["# Generated from design/other-shard-catalog.json; edit that catalog or its source order."]
    for family in FAMILIES:
        for grade, entry in enumerate(CATALOG[family]["grades"], 1):
            base = "SkillDrivenProgression.DeadeyeFocusTier1Shard" if grade == 1 else item(family, grade - 1)
            lines += [f"\n{item(family, grade)}:", f"  $base: {base}", f"  quality: Quality.{QUALITY[grade - 1]}", "  nextUpgradeItem: None"]
            if grade == 1:
                lines.append(f"  shardType: SDP{key(family)}")
            lines += ["  OnAttach:", "    - $type: GameplayLogicPackage", "      UIData:", "        $type: GameplayLogicPackageUIData", f"        localizedDescription: LocKey#{loc(family, grade, 'training')}", f"  displayName: LocKey#{loc(family, grade, 'name')}", f"  localizedDescription: LocKey#{loc(family, grade, 'description')}"]
    lines += ["\nSkillDrivenProgression.VehicleChip:", "  $base: SkillDrivenProgression.DeadeyeFocusTier1Shard", "  shardType: SDPVehicle", "  quality: Quality.Common", "  nextUpgradeItem: None", "  OnAttach:", "    - $type: GameplayLogicPackage", "      UIData:", "        $type: GameplayLogicPackageUIData", "        localizedDescription: LocKey#sdp_vehiclechip_training", "  displayName: LocKey#sdp_vehiclechip_name", "  localizedDescription: LocKey#sdp_vehiclechip_description"]
    for shard in EXPANSIONS:
        lines += [f"\n{chip(shard)}:", "  $base: SkillDrivenProgression.VehicleChip", f"  shardType: SDP{key(shard['name'])}",
                  "  quality: Quality.Rare", "  OnAttach:", "    - $type: GameplayLogicPackage", "      UIData:",
                  "        $type: GameplayLogicPackageUIData", f"        localizedDescription: LocKey#{chip_loc(shard, 'training')}",
                  f"  displayName: LocKey#{chip_loc(shard, 'name')}", f"  localizedDescription: LocKey#{chip_loc(shard, 'description')}"]
    (ROOT / "r6/tweaks/SkillDrivenProgression/ShardFamilies.generated.yaml").write_text("\n".join(lines) + "\n", encoding="utf-8")

    packages = ["# Private package copies owned by the mod. Source IDs are recorded in ShardPackageSources.generated.reds.",
                "# Package-free ranks use the perk-rank adapter; Chrome rank 3 also uses ShardChrome.reds."]
    for family in FAMILIES:
        for grade, entry in enumerate(CATALOG[family]["grades"], 1):
            for effect, rank in enumerate(entry["effects"], 1):
                if rank["package"] != "?":
                    packages += [f"\n{package(family, grade, effect)}:", f"  $base: {rank['package']}"]
    for effect, perk in enumerate(VEHICLE, 1):
        source = perk["level_packages"].split(";")[0]
        if source != "?":
            packages += [f"\n{package('Vehicle', 1, effect)}:", f"  $base: {source}"]
    (ROOT / "r6/tweaks/SkillDrivenProgression/ShardPackages.generated.yaml").write_text("\n".join(packages) + "\n", encoding="utf-8")

    # Base shards are sold by netrunner vendors (ripperdoc menus only list
    # cyberware, so shards never showed there). One explicit VendorItem per
    # stock entry, the pattern Chipware Expansion uses. Higher grades only
    # come from processor upgrades.
    stock = [item(family, 1) for family in FAMILIES]
    stock += ["SkillDrivenProgression.DeadeyeFocusTier1Shard",
              "SkillDrivenProgression.VehicleChip"]
    stock += [chip(shard) for shard in EXPANSIONS]
    vendors = ["# Generated base-shard stock; higher grades are upgrade-only.",
               "Vendors.$(vendor):", "  $instances:"]
    for vendor in ["hey_rey_netrunner_01", "wat_kab_netrunner_01",
                   "wat_lch_netrunner_01", "wbr_jpn_netrunner_01",
                   "wbr_jpn_netrunner_02", "cz_stadium_netrunner_01"]:
        vendors.append(f"    - {{ vendor: {vendor} }}")
    vendors.append("  itemStock:")
    for entry in stock:
        vendors += ["    - !append", "      $type: VendorItem", f"      item: {entry}",
                    "      quantity:", "        - Vendors.Always_Present"]
    (ROOT / "r6/tweaks/SkillDrivenProgression/ShardVendors.generated.yaml").write_text("\n".join(vendors) + "\n", encoding="utf-8")


def generate_catalog() -> None:
    lines = ["// Generated from design/other-shard-catalog.json. Do not edit manually.", "module SkillDrivenProgression", "", "public func SDP_FamilyItemFamily(itemID: TweakDBID) -> Int32 {"]
    for family_id, family in enumerate(FAMILIES, 1):
        for grade in range(1, 12):
            lines.append(f'  if Equals(itemID, t"{item(family, grade)}") {{ return {family_id}; }};')
    lines += ['  if Equals(itemID, t"SkillDrivenProgression.VehicleChip") { return 15; };']
    lines += [f'  if Equals(itemID, t"{chip(x)}") {{ return {x["family"]}; }};' for x in EXPANSIONS]
    lines += ["  return 0;", "}", "", "public func SDP_FamilyItemGrade(itemID: TweakDBID) -> Int32 {"]
    for family in FAMILIES:
        for grade in range(1, 12):
            lines.append(f'  if Equals(itemID, t"{item(family, grade)}") {{ return {grade}; }};')
    lines += ['  if Equals(itemID, t"SkillDrivenProgression.VehicleChip") { return 1; };']
    lines += [f'  if Equals(itemID, t"{chip(x)}") {{ return 1; }};' for x in EXPANSIONS]
    lines += ["  return 0;", "}", "", "public func SDP_FamilyItemID(family: Int32, grade: Int32) -> TweakDBID {"]
    for family_id, family in enumerate(FAMILIES, 1):
        for grade in range(1, 12):
            lines.append(f'  if family == {family_id} && grade == {grade} {{ return t"{item(family, grade)}"; }};')
    lines += ['  if family == 15 && grade == 1 { return t"SkillDrivenProgression.VehicleChip"; };']
    lines += [f'  if family == {x["family"]} && grade == 1 {{ return t"{chip(x)}"; }};' for x in EXPANSIONS]
    lines += ['  return t"None";', "}", "", "public func SDP_FamilyName(family: Int32) -> String {"]
    for family_id, family in enumerate(FAMILIES + ["Vehicle"], 1):
        lines.append(f'  if family == {family_id} {{ return "{family}"; }};')
    for x in EXPANSIONS:
        lines.append(f'  if family == {x["family"]} {{ return "{x["name"]}"; }};')
    lines += ['  return "Unknown";', "}", "", "public func SDP_FamilySkill(family: Int32) -> gamedataProficiencyType {"]
    for family_id, family in enumerate(FAMILIES, 1):
        linked = LEDGER[CATALOG[family]["grades"][0]["effects"][0]["perk"]]["linked_skill"]
        lines.append(f"  if family == {family_id} {{ return gamedataProficiencyType.{PROFICIENCY[linked]}; }};")
    lines += ["  return gamedataProficiencyType.Level;", "}", "", "public func SDP_FamilyEffectCount(family: Int32, grade: Int32) -> Int32 {"]
    for family_id, family in enumerate(FAMILIES, 1):
        for grade, entry in enumerate(CATALOG[family]["grades"], 1):
            lines.append(f"  if family == {family_id} && grade == {grade} {{ return {len(entry['effects'])}; }};")
    lines += [f"  if family == 15 && grade == 1 {{ return {len(VEHICLE)}; }};", "  return 0;", "}", "", "public func SDP_FamilyEffectPackage(family: Int32, grade: Int32, effect: Int32) -> TweakDBID {"]
    for family_id, family in enumerate(FAMILIES, 1):
        for grade, entry in enumerate(CATALOG[family]["grades"], 1):
            for effect, rank in enumerate(entry["effects"], 1):
                if rank["package"] != "?":
                    lines.append(f'  if family == {family_id} && grade == {grade} && effect == {effect} {{ return t"{package(family, grade, effect)}"; }};')
    for effect, perk in enumerate(VEHICLE, 1):
        if perk["level_packages"].split(";")[0] != "?":
            lines.append(f'  if family == 15 && grade == 1 && effect == {effect} {{ return t"{package("Vehicle", 1, effect)}"; }};')
    lines += ['  return t"None";', "}", "", "@addMethod(PlayerDevelopmentData)", "public final const func SDP_FamilyPerkRank(perkType: gamedataNewPerkType) -> Int32 {", "  let rank: Int32 = 0;"]
    grouped = {}
    for family_id, family in enumerate(FAMILIES, 1):
        for grade, entry in enumerate(CATALOG[family]["grades"], 1):
            for effect in entry["effects"]:
                grouped.setdefault(effect["perk"], []).append((family_id, grade, effect["rank"]))
    for effect in VEHICLE:
        grouped.setdefault(effect["record_id"], []).append((15, 1, 1))
    for perk, assignments in grouped.items():
        lines.append(f"  if Equals(perkType, gamedataNewPerkType.{perk.split('.')[-1]}) {{")
        for family_id, grade, level in sorted(assignments, key=lambda row: (-row[2], row[1])):
            lines.append(f"    if this.SDP_FamilyActiveGrade({family_id}) >= {grade} {{ return {level}; }};")
        lines.append("  };")
    lines += ["  return rank;", "}"]
    (ROOT / "r6/scripts/SkillDrivenProgression/ShardFamiliesCatalog.generated.reds").write_text("\n".join(lines) + "\n", encoding="utf-8")


def generate_package_sources() -> None:
    """Track clone provenance so old saves keep only one copy of each effect."""
    sources = {}
    for filename in ("ShardPackages.generated.yaml", "PerkPrototype.yaml"):
        text = (ROOT / "r6/tweaks/SkillDrivenProgression" / filename).read_text(encoding="utf-8")
        sources.update(re.findall(r"^(SkillDrivenProgression\.\w+):\s*\n  \$base: (NewPerks\.\w+)", text, re.M))
    lines = ["// Generated by tools/GenerateOtherShardAssets.py; private package -> vanilla source.",
             "module SkillDrivenProgression", "",
             "public func SDP_ShardPackageSource(packageID: TweakDBID) -> TweakDBID {"]
    for owned, source in sources.items():
        lines.append(f'  if Equals(packageID, t"{owned}") {{ return t"{source}"; }};')
    lines += ['  return t"None";', "}", ""]
    (ROOT / "r6/scripts/SkillDrivenProgression/ShardPackageSources.generated.reds").write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    generate_tweaks()
    generate_catalog()
    generate_package_sources()
    print("Generated family items, package copies, and redscript catalog")
