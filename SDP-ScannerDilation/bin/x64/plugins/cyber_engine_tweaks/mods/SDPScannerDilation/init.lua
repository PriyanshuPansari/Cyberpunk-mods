-- SDP Scanner Dilation: Native Settings for scanner time dilation by Netrunner skill.
local settingsFile = "settings.json"
local config = { scannerFirst = 0.99, scannerLast = 0.03 }

local function loadSettings()
  local file = io.open(settingsFile, "r")
  if not file then return end
  local ok, saved = pcall(json.decode, file:read("*a"))
  file:close()
  if not ok or type(saved) ~= "table" then return end
  config.scannerFirst = math.max(0.01, math.min(1, tonumber(saved.scannerFirst) or 0.99))
  config.scannerLast = math.max(0.01, math.min(1, tonumber(saved.scannerLast) or 0.03))
end

local function saveSettings()
  local file = io.open(settingsFile, "w")
  if not file then print("SDP Scanner Dilation: cannot save settings") return end
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
  if data then data:SDP_SetScannerDilationEndpoints(config.scannerFirst, config.scannerLast) end
end

local function addNativeSettings()
  local ui = GetMod("nativeSettings")
  if not ui then print("SDP Scanner Dilation: Native Settings UI unavailable") return end
  local root = "/SkillDrivenProgression"
  ensureTab(ui, root)
  ui.addSubcategory(root .. "/scanner", "Scanner time dilation")
  ui.addRangeFloat(root .. "/scanner", "At Netrunner level 1",
    "Time scale at the first skill level. 1.00 is normal speed; smaller values slow time more.",
    0.01, 1, 0.01, "%.2f", config.scannerFirst, 0.99, function(value)
      config.scannerFirst = value
      saveSettings()
      pcall(function() applySettings(developmentData()) end)
    end)
  ui.addRangeFloat(root .. "/scanner", "At maximum Netrunner level",
    "Time scale at the maximum skill level. The values between endpoints follow a smooth curve.",
    0.01, 1, 0.01, "%.2f", config.scannerLast, 0.03, function(value)
      config.scannerLast = value
      saveSettings()
      pcall(function() applySettings(developmentData()) end)
    end)
end

registerForEvent("onInit", function()
  loadSettings()
  addNativeSettings()
end)

-- Applied once per loaded character (the setter refreshes the dilation immediately).
local elapsed, applied = 0, nil
registerForEvent("onUpdate", function(delta)
  elapsed = elapsed + delta
  if elapsed < 3 then return end
  elapsed = 0
  pcall(function()
    local data = developmentData()
    if data and data ~= applied then applySettings(data); applied = data end
  end)
end)
