-- SDPVanillaDump: dev-only CET mod that dumps vanilla combat-AI TweakDB values.
-- Install: copy this folder to <game>\bin\x64\plugins\cyber_engine_tweaks\mods\SDPVanillaDump\
-- Runs automatically at game start. Re-run from the CET console with:
--     GetMod("SDPVanillaDump").run()
-- Output: vanilla_dump.json in this mod's folder. Disable ENC / Combat Revolution /
-- Combat Evolved / Harder Gunfights first, or the dump will contain their values.

local SDPDump = {}

local function str(v)
  if type(v) == "table" then
    local t = {}
    for i, x in ipairs(v) do t[i] = str(x) end
    return t
  end
  if type(v) == "userdata" then
    local ok, s = pcall(function() return v.value end)
    if ok and s ~= nil and s ~= "" then return tostring(s) end
  end
  return tostring(v)
end

local function flat(id, field)
  local ok, v = pcall(function() return TweakDB:GetFlat(id .. "." .. field) end)
  if ok and v ~= nil then return str(v) end
  return nil
end

local function dumpType(out, counts, typeName, fields)
  local okR, recs = pcall(function() return TweakDB:GetRecords(typeName) end)
  if not okR or recs == nil then
    counts[typeName] = "unknown type"
    return
  end
  local t, n = {}, 0
  for _, rec in ipairs(recs) do
    local ok, id = pcall(function() return rec:GetID().value end)
    if ok and id ~= nil and id ~= "" then
      local e = {}
      for _, f in ipairs(fields) do e[f] = flat(id, f) end
      t[id] = e
      n = n + 1
    end
  end
  out[typeName] = t
  counts[typeName] = n
end

function SDPDump.run()
  local out, counts = {}, {}

  dumpType(out, counts, "gamedataAIActionTicket_Record",
    {"maxNumberOfTickets", "minNumberOfTickets", "percentageNumberOfTickets", "timeout",
     "minTicketDesyncTime", "maxTicketDesyncTime", "activationCondition", "cooldowns", "ticketType"})
  dumpType(out, counts, "gamedataAIActionCooldown_Record", {"duration", "name"})
  dumpType(out, counts, "gamedataAIPattern_Record", {"patternSize", "delays"})
  dumpType(out, counts, "gamedataAIPatternDelay_Record", {"shotNumber", "delay"})
  dumpType(out, counts, "gamedataAISubActionShootWithWeapon_Record",
    {"numberOfShots", "maxNumberOfShots", "delay", "aimingDelay"})
  dumpType(out, counts, "gamedataThreatTrackingPresetBase_Record", {"trackingMode"})
  dumpType(out, counts, "gamedataSenses_Record", {"detectionFactor", "range"})

  out.TimeBetweenHits = {}
  for _, f in ipairs({"storyModeMultiplier", "easyModeMultiplier", "normalModeMultiplier",
                      "hardModeMultiplier", "coverVsNormalWeaponsMultiplier",
                      "coverVsSmartWeaponsMultiplier", "HMGGroupMultiplier"}) do
    out.TimeBetweenHits[f] = flat("TimeBetweenHits", f)
  end
  out._counts = counts

  local ok, err = pcall(function()
    local fh = io.open("vanilla_dump.json", "w")
    fh:write(json.encode(out))
    fh:close()
  end)

  for k, v in pairs(counts) do print("[SDPVanillaDump] " .. k .. ": " .. tostring(v)) end
  if ok then
    print("[SDPVanillaDump] wrote vanilla_dump.json")
  else
    print("[SDPVanillaDump] write failed: " .. tostring(err))
  end
  return counts
end

registerForEvent("onInit", function() SDPDump.run() end)

return SDPDump
