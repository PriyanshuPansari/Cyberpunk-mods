// Cyberware-EX (Nexus 9429) customization: the extra cyberware slots come from
// SDP's standalone Expansion shards instead of vanilla perks. Same areas and
// slot counts as Cyberware-EX's Extended mode. Each slot's "perk" requirement
// uses a sentinel level 100 + family (116-123); ShardExpansion.reds answers
// those prereqs from the matching Expansion shard. Compiles to nothing
// without Cyberware-EX.
module CyberwareEx.Customization

@if(ModuleExists("CyberwareEx"))
import CyberwareEx.*

@if(ModuleExists("CyberwareEx"))
public abstract class UserConfig {
  public static func SlotExpansions() -> array<ExpansionArea> = [
    ExpansionArea.Create(gamedataEquipmentArea.SystemReplacementCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 116),
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 116)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.FrontalCortexCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 117),
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 117)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.CardiovascularSystemCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 118)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.NervousSystemCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 119)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.IntegumentarySystemCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 120),
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 120)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.ArmsCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 121)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.HandsCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 122)
    ]),
    ExpansionArea.Create(gamedataEquipmentArea.LegsCW, [
      ExpansionSlot.Create(gamedataNewPerkType.Tech_Central_Milestone_3, 123)
    ])
  ];

  public static func SlotOverrides() -> array<OverrideArea> = OverrideConfig.DefaultSlotOverrides()
  public static func UpgradePrice() -> Int32 = OverrideConfig.DefaultUpgradePrice()
  public static func ResetPrice() -> Int32 = OverrideConfig.DefaultResetPrice()
  public static func CombinedAbilityMode() -> Bool = false
}
