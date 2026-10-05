module SDPCE

// CE archetype detection (chrome distribution itself is not part of the SDPCombat cut-down).

public class GBPChromeDetect {

  public static func ShouldSkip(puppet: ref<ScriptedPuppet>) -> Bool {
    if !IsDefined(puppet) { return true; }
    if puppet.IsBoss() { return true; }
    if puppet.IsMaxTac() { return true; }
    if puppet.IsDrone() { return true; }
    if puppet.IsMech() { return true; }

    let rid = puppet.GetRecordID();
    if NPCManager.HasTag(rid, n"Cyberpsycho") { return true; }
    if NPCManager.HasTag(rid, n"Quest") { return true; }

    if GBPChromeDetect.IsQuestGroup(puppet) { return true; }

    return false;
  }

  private static func IsQuestGroup(puppet: ref<ScriptedPuppet>) -> Bool {
    let agent: ref<AttitudeAgent> = puppet.GetAttitudeAgent();
    if !IsDefined(agent) { return false; }
    let g: String = StrLower(NameToString(agent.GetAttitudeGroup()));
    if StrLen(g) < 6 { return false; }
    return Equals(StrMid(g, 0, 1), "q")
        && GBPChromeDetect.IsDigit(StrMid(g, 1, 1))
        && GBPChromeDetect.IsDigit(StrMid(g, 2, 1))
        && GBPChromeDetect.IsDigit(StrMid(g, 3, 1))
        && Equals(StrMid(g, 4, 1), "_");
  }

  public static func ArchetypeEnum(puppet: ref<ScriptedPuppet>) -> String {
    let rec = TweakDBInterface.GetCharacterRecord(puppet.GetRecordID());
    if !IsDefined(rec) { return ""; }
    let archRec = rec.ArchetypeData();
    if !IsDefined(archRec) { return ""; }
    let typeRec = archRec.Type();
    if !IsDefined(typeRec) { return ""; }
    return StrLower(NameToString(typeRec.EnumName()));
  }

  public static func Archetype(puppet: ref<ScriptedPuppet>) -> GBPChromeArchetype {
    let e: String = GBPChromeDetect.ArchetypeEnum(puppet);
    if StrLen(e) == 0 { return GBPChromeArchetype.Unknown; }

    if StrBeginsWith(e, "netrunner") { return GBPChromeArchetype.Netrunner; }
    if StrBeginsWith(e, "heavymelee") || StrBeginsWith(e, "hybridheavyfastmelee") { return GBPChromeArchetype.HeavyMelee; }
    if StrBeginsWith(e, "fastmelee") { return GBPChromeArchetype.FastMelee; }
    if StrContains(e, "melee")       { return GBPChromeArchetype.GenericMelee; }
    
    if Equals(puppet.GetNPCRarity(), gamedataNPCRarity.Officer) { return GBPChromeArchetype.Officer; }
    if StrContains(e, "sniper")      { return GBPChromeArchetype.Sniper; }
    if StrContains(e, "shotgunner")  { return GBPChromeArchetype.Shotgunner; }
    if StrBeginsWith(e, "heavyranged") { return GBPChromeArchetype.HeavyRanged; }
    if StrBeginsWith(e, "fastranged") { return GBPChromeArchetype.FastRanged; }
    if StrContains(e, "ranged")      { return GBPChromeArchetype.GenericRanged; }
    return GBPChromeArchetype.Unknown;   
  }

  public static func Tier(puppet: ref<ScriptedPuppet>) -> Int32 {
    let e: String = GBPChromeDetect.ArchetypeEnum(puppet);
    if StrEndsWith(e, "t3") { return 3; }
    if StrEndsWith(e, "t2") { return 2; }
    if StrEndsWith(e, "t1") { return 1; }
    let r = puppet.GetNPCRarity();
    if Equals(r, gamedataNPCRarity.Elite) || Equals(r, gamedataNPCRarity.Officer) { return 3; }
    if Equals(r, gamedataNPCRarity.Rare) { return 2; }
    return 1;
  }

  private static func IsDigit(s: String) -> Bool {
    return Equals(s, "0") || Equals(s, "1") || Equals(s, "2") || Equals(s, "3") || Equals(s, "4")
        || Equals(s, "5") || Equals(s, "6") || Equals(s, "7") || Equals(s, "8") || Equals(s, "9");
  }
}
