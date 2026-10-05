// SDPCombat: armour as its own object (realism pass, section 12c).
// Health and weapon damage stay vanilla. Armour decides whether a round reaches the body:
//   - each combatant wears a few pieces; a piece has a rating P (0-7), an integrity (1 = intact) and the body parts it covers
//   - effective P = P x (0.5 + 0.5 x integrity): damaged armour stops less
//   - a round that gets through does full damage and holes the piece (-1% integrity)
//   - a round that is stopped does blunt trauma only (20% body, 30% head) and wears the piece: -2.5% x calibre^2 / P
//   - a piece at 0 integrity is broken and protects nothing
//   - a round through the head (unprotected, broken, or penetrated) is fatal, for V and NPCs alike
//   - subdermal plating (V, Maelstrom) is skin-bonded and self-repairs out of combat only: full repair in 90 s.
//     V: out of combat = the game's own combat state, checked every 2 s. NPCs: 60 s without being hit.
//     Worn gear (vests, helmets, plates) does not repair. (An in-fight repair tool is planned.)
// V's subdermal armour comes from her Armor stat (vanilla cyberware) and covers her whole body, head included.
// NPC kits come from faction, archetype and rarity; helmets from the model's armoured head hit shapes.
// Where Enemies of Night City gives a character subdermal armour (light / normal / medium / high), that tier sets the
// subdermal rating (2 / 3 / 4 / 5) in place of the faction default.
module SDPCombat

public class SDPArmorPiece {
  public let name: String;
  public let rating: Float;
  public let integrity: Float;
  public let covers: Int32;       // bit mask: 1 head, 2 torso, 4 legs, 8 arms
  public let selfRepair: Bool;

  public static func Make(name: String, rating: Float, covers: Int32, selfRepair: Bool) -> ref<SDPArmorPiece> {
    let p = new SDPArmorPiece();
    p.name = name;
    p.rating = MaxF(0.0, rating);
    p.integrity = 1.0;
    p.covers = covers;
    p.selfRepair = selfRepair;
    return p;
  }

  public final func Covers(part: Int32) -> Bool {
    let bit = 0;
    if part == 1 { bit = 1; };
    if part == 2 { bit = 2; };
    if part == 3 { bit = 4; };
    if part == 4 { bit = 8; };
    return (this.covers & bit) != 0;
  }
}

public class SDPArmorKit {
  public let pieces: array<ref<SDPArmorPiece>>;
  public let lastHit: Float;
  public let lastUpdate: Float;
  public let label: String;
  public let helmetChecked: Bool;
  public let repairedByTick: Bool;   // V: repaired by the combat-state tick, not by Update()
  public let counted: Bool;          // tallied in the report's kit list

  public final func Add(piece: ref<SDPArmorPiece>) -> Void {
    if piece.rating > 0.0 { ArrayPush(this.pieces, piece); };
  }

  // the intact piece with the highest effective rating over this body part
  public final func Covering(part: Int32) -> ref<SDPArmorPiece> {
    let best: ref<SDPArmorPiece>;
    let bestP = -1.0;
    for p in this.pieces {
      if p.integrity > 0.0 && p.Covers(part) {
        let eff = SDPArmor.EffectiveRating(p);
        if eff > bestP { best = p; bestP = eff; };
      };
    };
    return best;
  }

  public final func HasPieceFor(part: Int32) -> Bool {
    for p in this.pieces { if p.Covers(part) { return true; }; };
    return false;
  }

  // NPCs: self-repair of skin-bonded plating once not hit for 60 s, full in 90 s
  public final func Update(now: Float) -> Void {
    if this.repairedByTick { return; };
    let from = MaxF(this.lastUpdate, this.lastHit + 60.0);
    if now > from { this.Repair((now - from) / 90.0); };
    this.lastUpdate = now;
  }

  public final func Repair(fraction: Float) -> Void {
    for p in this.pieces {
      if p.selfRepair { p.integrity = MinF(1.0, p.integrity + fraction); };
    };
  }

  public final func Describe() -> String {
    let s = this.label + ":";
    for p in this.pieces {
      s += s" \(p.name) P\(p.rating) \(Cast<Int32>(100.0 * p.integrity))%";
    };
    return s;
  }
}

@addField(NPCPuppet) public let m_sdpcArmor: ref<SDPArmorKit>;

public abstract class SDPArmor {

  public static func EffectiveRating(p: ref<SDPArmorPiece>) -> Float {
    return p.rating * (0.5 + 0.5 * ClampF(p.integrity, 0.0, 1.0));
  }

  public static func Wear(calibre: Float, rating: Float) -> Float {
    return 0.025 * calibre * calibre / MaxF(0.5, rating);
  }

  // protection rating from the vanilla Armor stat and armour effectiveness (P = 8 x a / (1 + a))
  public static func RatingFromStat(target: ref<GameObject>) -> Float {
    let game = target.GetGame();
    let stats = GameInstance.GetStatsSystem(game);
    let id = Cast<StatsObjectID>(target.GetEntityID());
    let armorPoints = stats.GetStatValue(id, gamedataStatType.Armor);
    let effectiveness = GameInstance.GetStatsDataSystem(game).GetArmorEffectivenessValue(target.IsPlayer());
    if target.IsPlayer() { effectiveness *= stats.GetStatValue(id, gamedataStatType.ArmorEffectivenessMultiplier); };
    let a = MaxF(0.0, armorPoints * effectiveness);
    return 8.0 * a / (1.0 + a);
  }

  public static func IsHeavy(npc: ref<NPCPuppet>) -> Bool {
    let record = npc.GetRecord();
    if !IsDefined(record) || !IsDefined(record.ArchetypeData()) || !IsDefined(record.ArchetypeData().Type()) { return false; };
    let t = record.ArchetypeData().Type().Type();
    return Equals(t, gamedataArchetypeType.HeavyRangedT2) || Equals(t, gamedataArchetypeType.HeavyRangedT3)
      || Equals(t, gamedataArchetypeType.HeavyMeleeT2) || Equals(t, gamedataArchetypeType.HeavyMeleeT3);
  }

  public static func ForNPC(npc: ref<NPCPuppet>) -> ref<SDPArmorKit> {
    if IsDefined(npc.m_sdpcArmor) { return npc.m_sdpcArmor; };
    let kit = new SDPArmorKit();
    let a = SDPProfiles.Affiliation(npc);
    let rarity = npc.GetNPCRarity();
    let shift = 0.0;
    if Equals(rarity, gamedataNPCRarity.Trash) || Equals(rarity, gamedataNPCRarity.Weak) { shift = -1.0; };
    if Equals(rarity, gamedataNPCRarity.Elite) || Equals(rarity, gamedataNPCRarity.Officer) { shift = 1.0; };
    let all = 1 | 2 | 4 | 8;

    if npc.IsMechanical() || npc.IsDrone() {
      kit.label = "hull";
      kit.Add(SDPArmorPiece.Make("hull", 7.0, all, false));
    } else {
      if Equals(rarity, gamedataNPCRarity.MaxTac) {
        kit.label = "MaxTac";
        kit.Add(SDPArmorPiece.Make("military plate", 6.0, 2, false));
        kit.Add(SDPArmorPiece.Make("borg plating", 5.0, all, true));
        kit.Add(SDPArmorPiece.Make("helmet", 6.0, 1, false));
      } else {
        if SDPArmor.IsHeavy(npc) {
          kit.label = "heavy";
          kit.Add(SDPArmorPiece.Make("military plate", 6.0 + shift, 2, false));
          kit.Add(SDPArmorPiece.Make("limb plates", 4.0 + shift, 4 | 8, false));
          kit.Add(SDPArmorPiece.Make("helmet", 5.0 + shift, 1, false));
        } else {
          if Equals(a, gamedataAffiliation.Maelstrom) {
            kit.label = "Maelstrom";
            kit.Add(SDPArmorPiece.Make("subdermal plating", 2.0 + shift, all, true));
          } else {
            if Equals(a, gamedataAffiliation.SixthStreet) || Equals(a, gamedataAffiliation.Barghest)
              || Equals(a, gamedataAffiliation.NCPD) {
              kit.label = "vest";
              kit.Add(SDPArmorPiece.Make("ballistic vest", 3.0 + shift, 2, false));
            } else {
              if Equals(a, gamedataAffiliation.Arasaka) || Equals(a, gamedataAffiliation.Militech)
                || Equals(a, gamedataAffiliation.KangTao) || Equals(a, gamedataAffiliation.Biotechnica)
                || Equals(a, gamedataAffiliation.Zetatech) || Equals(a, gamedataAffiliation.NetWatch)
                || Equals(a, gamedataAffiliation.UnaffiliatedCorpo) || Equals(a, gamedataAffiliation.SSI)
                || Equals(a, gamedataAffiliation.Classified) || Equals(a, gamedataAffiliation.NUSA)
                || Equals(a, gamedataAffiliation.TraumaTeam) || Equals(a, gamedataAffiliation.AfterlifeMercs) {
                kit.label = "corporate";
                kit.Add(SDPArmorPiece.Make("vest and plating", 4.0 + shift, 2, false));
                kit.Add(SDPArmorPiece.Make("limb plating", 2.0 + shift, 4 | 8, false));
              } else {
                if Equals(a, gamedataAffiliation.Scavengers) || Equals(a, gamedataAffiliation.Wraiths)
                  || Equals(a, gamedataAffiliation.Unaffiliated) || Equals(a, gamedataAffiliation.Civilian) {
                  kit.label = "street";
                  kit.Add(SDPArmorPiece.Make("jacket", 0.5 + MaxF(0.0, shift), 2 | 8, false));
                } else {
                  kit.label = "gang";
                  kit.Add(SDPArmorPiece.Make("armoured jacket", 1.0 + shift, 2 | 8, false));
                };
              };
            };
          };
        };
      };
    };
    // Enemies of Night City assigns subdermal armour per character (light / normal / medium / high ability groups).
    // Where it does, that tier sets the subdermal rating; the faction table above is the fallback.
    if !npc.IsMechanical() && !npc.IsDrone() {
      let encName: String;
      let encP = SDPArmor.ENCSubdermal(npc, encName);
      if encP > 0.0 {
        let found = false;
        for p in kit.pieces {
          if p.selfRepair && p.covers == all {
            p.rating = Equals(rarity, gamedataNPCRarity.MaxTac) ? MaxF(p.rating, encP) : encP;
            found = true;
          };
        };
        if !found { kit.Add(SDPArmorPiece.Make("subdermal plating", encP, all, true)); };
        kit.label += " +" + encName;
      };
    };
    npc.m_sdpcArmor = kit;
    return kit;
  }

  // Subdermal tier on this NPC's archetype (ENC group or the game's ability): 2 light, 3 normal, 4 medium, 5 high; 0 when none.
  public static func ENCSubdermal(npc: ref<NPCPuppet>, out tierName: String) -> Float {
    let record = npc.GetRecord();
    if !IsDefined(record) || !IsDefined(record.ArchetypeData()) { return 0.0; };
    let groups: array<wref<GameplayAbilityGroup_Record>>;
    record.ArchetypeData().AbilityGroups(groups);
    let best = 0.0;
    let name: String;
    for g in groups {
      if IsDefined(g) {
        let p = SDPArmor.ENCTier(g.GetID(), name);
        if p > best { best = p; tierName = name; };
        if p <= 0.0 {
          // the game's subdermal ability inside a differently named group
          let abilities: array<wref<GameplayAbility_Record>>;
          g.Abilities(abilities);
          for a in abilities {
            if IsDefined(a) {
              let q = SDPArmor.ENCTier(a.GetID(), name);
              if q > best { best = q; tierName = name; };
            };
          };
        };
      };
    };
    return best;
  }

  // Exact IDs, confirmed in ENC's Base.lua (PL-Beta-1.8.8): ENC's ability groups, and the game's own subdermal
  // abilities they contain (vanilla archetypes that carry those abilities count too). The _Mechanical variants
  // (androids) are not read: mechanical NPCs wear the hull kit.
  private static func ENCTier(id: TweakDBID, out tierName: String) -> Float {
    if id == t"SubdermalHighAbilityGrp" { tierName = "ENC subdermal high"; return 5.0; };
    if id == t"SubdermalMedAbilityGrp" { tierName = "ENC subdermal medium"; return 4.0; };
    if id == t"SubdermalNormalAbilityGrp" { tierName = "ENC subdermal normal"; return 3.0; };
    if id == t"SubdermalLightAbilityGrp" { tierName = "ENC subdermal light"; return 2.0; };
    if id == t"Ability.HasSubdermalArmorHigh" { tierName = "subdermal high"; return 5.0; };
    if id == t"Ability.HasSubdermalArmorMedium" { tierName = "subdermal medium"; return 4.0; };
    if id == t"Ability.HasSubdermalArmor" { tierName = "subdermal normal"; return 3.0; };
    if id == t"Ability.HasSubdermalArmorLow" { tierName = "subdermal light"; return 2.0; };
    return 0.0;
  }

  // An armoured head hit shape (helmet, face plate) on a kit without head protection becomes a helmet piece.
  public static func CheckHelmet(kit: ref<SDPArmorKit>, hitEvent: ref<gameHitEvent>) -> Void {
    if kit.helmetChecked || kit.HasPieceFor(1) { return; };
    let shapes = hitEvent.hitRepresentationResult.hitShapes;
    if ArraySize(shapes) == 0 { return; };
    let data = DamageSystemHelper.GetHitShapeUserDataBase(shapes[0]);
    if !IsDefined(data) || !Equals(data.m_hitReactionZone, EHitReactionZone.Head) { return; };
    kit.helmetChecked = true;
    if DamageSystemHelper.IsHitShapeArmored(data.m_hitShapeType) {
      let best = 0.0;
      for p in kit.pieces { best = MaxF(best, p.rating); };
      kit.Add(SDPArmorPiece.Make("helmet", MaxF(3.0, best), 1, false));
    };
  }
}
