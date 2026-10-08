// SDP TestLab scenario catalog, revision 1.
// Location data is read from Combat Arena by whisperOfIndigo (Nexus 27580).
// No archive/assets are redistributed. ArenaData is a required dependency.
// These are qualification presets: record names do not prove armor/chrome/AI.
// See design/scenario-source-audit.json for source hashes and measured distances.

public abstract class SDPTLScenario {
  public static func Revision() -> Int32 { return 1; }
  public static func Count() -> Int32 { return 11; }

  public static func IsValid(index: Int32) -> Bool {
    return index >= 0 && index < SDPTLScenario.Count();
  }

  public static func Name(index: Int32) -> String {
    switch index {
      case 0: return "Heavy armor target qualification";
      case 1: return "Single shooter / injury baseline";
      case 2: return "Two matched shooters";
      case 3: return "Four matched shooters";
      case 4: return "Lost-target / cover qualification";
      case 5: return "Grenade / squad qualification";
      case 6: return "Mantis chrome qualification";
      case 7: return "One netrunner qualification";
      case 8: return "Mixed squad qualification";
      case 9: return "Two netrunners";
      case 10: return "Four netrunners";
    };
    return "Invalid scenario";
  }

  public static func Notes(index: Int32) -> String {
    switch index {
      case 0: return "Heavy record candidate. Inspect effective armor/gear first. Scan and aim without firing for D01; reload baseline before damage trials. Spawn distance is 10.678 m, not a calibrated 10 m lane.";
      case 1: return "One Copperhead shooter. Fix V weapon, level and difficulty. Verify actor equipment/health and floor before injury or damage measurements. No injury/armor reset is implied by respawn.";
      case 2: return "Two copies of the same character record, at different fixed points. Verify resolved equipment; record identity alone does not fix native item rolls or AI randomness.";
      case 3: return "Four matched record candidates. Fixed starts do not imply matched equipment or deterministic AI. Record incoming-hit attribution, firing cadence and failed setups.";
      case 4: return "Qualify an opaque cover route in the Pit, then observe, break sight and relocate. This preset supplies no cover assets, reveal stimulus, forced search target or verified occlusion route.";
      case 5: return "Militech grenadier candidate plus Militech rifle support near V. First prove throws and shared squad/ticket membership. No finite grenade inventory or friendly-fire behavior is supplied by this preset.";
      case 6: return "Arasaka mantis candidate. Confirm resolved abilities and actual activation. This release does not fabricate unequipped/disabled hardware variants.";
      case 7: return "Arasaka runner candidate. Prove one natural upload before concurrency tests. A successful spawn is not proof of hacking eligibility, network access or upload completion.";
      case 8: return "Arasaka rifle, heavy, mantis and runner candidates. Confirm abilities and shared squad membership first. Identical faction alone does not establish a coordinated squad.";
      case 9: return "Two copies of the qualified runner candidate. Record uploads, retries, source attribution, interrupt/effect outcomes and HUD conflicts. Native ticket or single-owner state may serialize attacks.";
      case 10: return "Four copies of the qualified runner candidate. Preserve native gates and measure observed concurrency. A shared network, squad or four simultaneous uploads is not asserted.";
    };
    return "Invalid scenario; setup must be refused.";
  }

  public static func Suite(index: Int32) -> String {
    switch index {
      case 0: return "D01,D02,D04";
      case 1: return "D02,D03,D04";
      case 2: return "D03,A03";
      case 3: return "D03,A03";
      case 4: return "A01";
      case 5: return "A04,A05";
      case 6: return "C01";
      case 7: return "N01,N04";
      case 8: return "A06,A07,A08,H02";
      case 9: return "N01,N04";
      case 10: return "N01,N04";
    };
    return "INVALID";
  }

  public static func NeedsQualification(index: Int32) -> Bool {
    // All revision-1 presets are source-selected, not gameplay-qualified.
    return true;
  }

  public static func ActorRecords(index: Int32) -> array<TweakDBID> {
    let result: array<TweakDBID>;
    switch index {
      case 0:
        return [t"Character.arasaka_tank2_gunner2_defender_mb_rare"];
      case 1:
      case 4:
        return [t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma"];
      case 2:
        return [t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma", t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma"];
      case 3:
        return [t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma", t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma", t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma", t"Character.cpz_maelstrom_grunt1_ranged1_copperhead_ma"];
      case 5:
        return [t"Character.militech_tech_grenadier2_omaha_ma_rare", t"Character.militech_ranger1_ranged1_saratoga_ma"];
      case 6:
        return [t"Character.arasaka_ninja_fmelee3_mantis_ma_elite"];
      case 7:
        return [t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare"];
      case 8:
        return [t"Character.arasaka_ranger1_ranged2_masamune_ma", t"Character.arasaka_tank2_gunner2_defender_mb_rare", t"Character.arasaka_ninja_fmelee3_mantis_ma_elite", t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare"];
      case 9:
        return [t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare"];
      case 10:
        return [t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare"];
    };
    return result;
  }

  // Zero-based indices into the installed ArenaData.ArenaPoints() array.
  public static func PointIndices(index: Int32) -> array<Int32> {
    let result: array<Int32>;
    if !SDPTLScenario.IsValid(index) { return result; };
    switch index {
      case 2:
      case 9: return [16, 11];
      case 3:
      case 8:
      case 10: return [16, 11, 5, 2];
      case 5: return [16, 1];
    };
    return [16];
  }

  public static func PlayerPointIndex() -> Int32 { return 12; }

  // Pin the six used points rather than silently accepting a changed map layout.
  // A 1 cm tolerance only accommodates float representation, not map migration.
  // This checks source geometry identity, NOT loaded collision/navmesh/cover.
  public static func HasLocationData() -> Bool {
    let points = ArenaData.ArenaPoints();
    if ArraySize(points) <= 16 { return false; };
    if Vector4.Distance(points[1], new Vector4(-1425.9408, 139.69693, 206.6265, 1.0)) > 0.01 { return false; };
    if Vector4.Distance(points[2], new Vector4(-1413.5193, 115.183655, 206.6265, 1.0)) > 0.01 { return false; };
    if Vector4.Distance(points[5], new Vector4(-1437.1752, 162.42181, 206.62624, 1.0)) > 0.01 { return false; };
    if Vector4.Distance(points[11], new Vector4(-1417.15, 153.89804, 206.62599, 1.0)) > 0.01 { return false; };
    if Vector4.Distance(points[12], new Vector4(-1425.4507, 144.2837, 206.6265, 1.0)) > 0.01 { return false; };
    if Vector4.Distance(points[16], new Vector4(-1434.9348, 149.1905, 206.6265, 1.0)) > 0.01 { return false; };
    return true;
  }

  public static func Positions(index: Int32) -> array<Vector4> {
    let result: array<Vector4>;
    let slots: array<Int32>;
    let points: array<Vector4>;
    let i: Int32 = 0;
    if !SDPTLScenario.IsValid(index) || !SDPTLScenario.HasLocationData() { return result; };
    slots = SDPTLScenario.PointIndices(index);
    points = ArenaData.ArenaPoints();
    while i < ArraySize(slots) {
      ArrayPush(result, points[slots[i]]);
      i += 1;
    };
    return result;
  }

  // Callers must pass IsValid/HasLocationData before teleporting. An invalid
  // result has W=0 and must never be treated as a fallback world destination.
  public static func PlayerPosition(index: Int32) -> Vector4 {
    let points: array<Vector4>;
    if !SDPTLScenario.IsValid(index) || !SDPTLScenario.HasLocationData() { return new Vector4(0.0, 0.0, 0.0, 0.0); };
    points = ArenaData.ArenaPoints();
    return points[SDPTLScenario.PlayerPointIndex()];
  }

  public static func Facing(index: Int32, slot: Int32) -> Float {
    let positions = SDPTLScenario.Positions(index);
    let angles: EulerAngles;
    if slot < 0 || slot >= ArraySize(positions) { return 0.0; };
    angles = Vector4.ToRotation(SDPTLScenario.PlayerPosition(index) - positions[slot]);
    return angles.Yaw;
  }

  public static func PlayerYaw(index: Int32) -> Float {
    let positions = SDPTLScenario.Positions(index);
    let angles: EulerAngles;
    if ArraySize(positions) == 0 { return 0.0; };
    angles = Vector4.ToRotation(positions[0] - SDPTLScenario.PlayerPosition(index));
    return angles.Yaw;
  }

  public static func PlannedDistance(index: Int32, slot: Int32) -> Float {
    let positions = SDPTLScenario.Positions(index);
    if slot < 0 || slot >= ArraySize(positions) { return -1.0; };
    return Vector4.Distance(SDPTLScenario.PlayerPosition(index), positions[slot]);
  }
}
