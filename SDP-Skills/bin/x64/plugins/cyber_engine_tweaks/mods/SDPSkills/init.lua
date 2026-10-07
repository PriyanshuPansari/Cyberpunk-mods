-- SDP Skills: Native Settings for the skills' base passives and Cyberware Capacity per skill level.
-- Shares the "Skill Driven Progression" settings tab with the other SDP parts.
local settingsFile = "settings.json"
local passiveNames = {
  "Solo health", "Shinobi critical chance", "Engineer armor",
  "Netrunner memory", "Headhunter critical damage"
}
local config = { passive = { 100, 100, 100, 100, 100 }, capacityPerSkill = 1.00 }

local function loadSettings()
  local file = io.open(settingsFile, "r")
  if not file then return end
  local ok, saved = pcall(json.decode, file:read("*a"))
  file:close()
  if not ok or type(saved) ~= "table" then return end
  if type(saved.passive) == "table" then
    for i = 1, 5 do
      local value = tonumber(saved.passive[i])
      if value then config.passive[i] = math.max(0, math.min(300, value)) end
    end
  end
  config.capacityPerSkill = math.max(0, math.min(3, tonumber(saved.capacityPerSkill) or 1.00))
end

local function saveSettings()
  local file = io.open(settingsFile, "w")
  if not file then print("SDP Skills: cannot save settings") return end
  file:write(json.encode(config))
  file:close()
end

local function developmentData()
  local player = Game.GetPlayer()
  if not player then return nil end
  local system = PlayerDevelopmentSystem.GetInstance(player)
  return system and system:GetDevelopmentData(player) or nil
end

local function ensureTab(ui, root)
  local ok, exists = pcall(function() return ui.pathExists(root) end)
  if not (ok and exists) then pcall(function() ui.addTab(root, "Skill Driven Progression") end) end
end

local function applySettings(data)
  if not data then return end
  for index = 0, 4 do data:SDP_TuningSetPassiveScale(index, config.passive[index + 1] / 100) end
  data:SDP_TuningSetCapacityPerSkill(config.capacityPerSkill)
end

local function addNativeSettings()
  local ui = GetMod("nativeSettings")
  if not ui then print("SDP Skills: Native Settings UI unavailable") return end
  local root = "/SkillDrivenProgression"
  ensureTab(ui, root)
  ui.addSubcategory(root .. "/passives", "Skill passives")
  for index = 0, 4 do
    local i = index + 1
    ui.addRangeInt(root .. "/passives", passiveNames[i],
      "Scales this skill's base passive only. Cyberware and item effects retain their existing skill scaling.",
      0, 300, 5, config.passive[i], 100, function(value)
        config.passive[i] = value
        saveSettings()
        pcall(function() local data = developmentData(); if data then data:SDP_TuningSetPassiveScale(index, value / 100) end end)
      end)
  end
  ui.addSubcategory(root .. "/capacity", "Cyberware capacity")
  ui.addRangeFloat(root .. "/capacity", "Capacity per skill level",
    "Each of the five skills contributes this much Cyberware Capacity per level. Default 1.00.",
    0, 3, 0.05, "%.2f", config.capacityPerSkill, 1.00, function(value)
      config.capacityPerSkill = value
      saveSettings()
      pcall(function() local data = developmentData(); if data then data:SDP_TuningSetCapacityPerSkill(value) end end)
    end)
end

registerForEvent("onInit", function()
  loadSettings()
  addNativeSettings()
end)

-- Setters return early when nothing changed, so re-applying every few seconds is cheap
-- and covers loads, new games and character switches.
local elapsed = 0
registerForEvent("onUpdate", function(delta)
  elapsed = elapsed + delta
  if elapsed < 3 then return end
  elapsed = 0
  pcall(function() applySettings(developmentData()) end)
end)
