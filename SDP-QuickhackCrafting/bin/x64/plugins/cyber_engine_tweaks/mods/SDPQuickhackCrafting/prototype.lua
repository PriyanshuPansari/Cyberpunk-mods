local recipes = require("prototype_recipes")
local M = {}
local visible, overlayOpen = false, false
local recipe = recipes.copy(recipes.presets[1])
local message = "Enable the workbench, choose components, then upload or build."
local status = "Disabled."
local elapsed = 0
local build = 9
local tickElapsed = 0
local labIndex, labAudit = 0, "Inspect an equipped native quickhack to see its components."
local targetAudit = "No target snapshot captured."
local lastSpreadSequence = 0
local traceRecording = false
local expectedStatus = {
  ["SkillDrivenProgression.PrototypeBlind"] = true,
  ["SkillDrivenProgression.PrototypeBurn"] = true,
  ["SkillDrivenProgression.PrototypeShock"] = true,
  ["SkillDrivenProgression.PrototypeStun"] = true,
}

local function call(action)
  local player = Game.GetPlayer()
  if not player then message = "Load a save first."; return end
  local versionOK, version = pcall(function() return player:SDP_PrototypeVersion() end)
  local ok, result
  if not versionOK or version ~= build then
    ok, result = true, "Build mismatch: restart after updating the game's prototype scripts (workbench build 9)."
    visible = true
  else
    ok, result = pcall(action, player)
  end
  message = ok and tostring(result) or ("Prototype unavailable: " .. tostring(result))
  print("SDP Workbench: " .. message)
  -- Feedback must be visible even when the workbench and CET overlay are closed.
  local notified = pcall(function() player:SDP_PrototypeNotify(message) end)
  if not notified then visible = true end
end

local function enable()
  call(function(player)
    for id in pairs(expectedStatus) do
      if not TweakDB:GetRecord(id) then return "Missing payload record: " .. id .. ". Deploy scripts and tweaks together." end
    end
    return player:SDP_PrototypeEnable(true)
  end)
end

local function assemble(player, weapon)
  local valid, reason = recipes.validate(recipe, weapon)
  if not valid then return false, reason end
  local a, b = recipe.first, recipe.second
  local result = player:SDP_PrototypeAssemble(a[1], a[2], a[3], b[1], b[2], b[3])
  if result ~= "Recipe assembled. Upload it or bind it to your held gun." then return false, result end
  for slot, rule in ipairs({a, b}) do
    if not player:SDP_PrototypeConfigure(slot, rule[4] or 4, rule[5] or 25, rule[6] or 1) then
      return false, "Invalid primitive parameters; upload cancelled."
    end
    if rule[2] == 5 then
      local id = slot == 1 and recipe.nativeFirst or recipe.nativeSecond
      if not player:SDP_PrototypeSetNative(slot, TweakDBID.new(id)) then
        return false, "Native status is unavailable/unsupported: " .. id
      end
    end
  end
  -- The backend independently validates all inputs; do not upload a stale recipe on failure.
  return result == "Recipe assembled. Upload it or bind it to your held gun.", result
end

local function upload()
  call(function(player)
    local ok, result = assemble(player, false)
    if not ok then return result end
    return player:SDP_PrototypeUpload()
  end)
end

local function bindWeapon()
  call(function(player)
    local ok, result = assemble(player, true)
    if not ok then return result end
    return player:SDP_PrototypeBindWeapon()
  end)
end

local function propagate()
  call(function(player) return player:SDP_PrototypePropagate() end)
end

local function rearm()
  call(function(player) return player:SDP_PrototypeRearm() end)
end

local function spreadNative()
  call(function(player) return player:SDP_LabSpreadNative() end)
end

local function inspectTarget()
  call(function(player)
    targetAudit = player:SDP_LabInspectTarget()
    return targetAudit
  end)
end

local function startTrace()
  call(function(player)
    if traceRecording then return "Recording already running; wait for it to finish." end
    local file = io.open("optics-runtime.log", "a")
    if not file then return "Cannot open optics-runtime.log; recording was not started." end
    local result = player:SDP_OpticsTraceStart()
    if result:find("Recording started:", 1, true) == 1 then
      file:write("\nSESSION ", os.date("%Y-%m-%d %H:%M:%S"), "\n")
      traceRecording = true
    end
    file:close()
    return result
  end)
end

local function updateTrace()
  if not traceRecording then return end
  local player = Game.GetPlayer()
  local ok, text = pcall(function()
    return player and player:SDP_OpticsTraceDrain() or "ABORT player unloaded\n"
  end)
  if not ok then
    traceRecording = false
    message = "Recording failed: " .. tostring(text)
    print("SDP Workbench: " .. message)
    return
  end
  if text == "" then return end
  local file = io.open("optics-runtime.log", "a")
  if not file then
    traceRecording = false
    message = "Recording stopped: could not write optics-runtime.log."
    print("SDP Workbench: " .. message)
    return
  end
  local written = file:write(text)
  file:close()
  if not written then
    traceRecording = false
    message = "Recording failed while writing optics-runtime.log."
    print("SDP Workbench: " .. message)
  elseif text:find("END dropped=", 1, true) or text:find("ABORT", 1, true) then
    traceRecording = false
    message = "Recording ended. Results saved to optics-runtime.log."
    print("SDP Workbench: " .. message)
    if player then pcall(function() player:SDP_PrototypeNotify(message) end) end
  end
end

local function inspectNative(step)
  call(function(player)
    local count = player:SDP_LabCount()
    if count == 0 then labAudit = "Equip a cyberdeck with quickhacks first."; return labAudit end
    labIndex = (labIndex + step) % count
    labAudit = player:SDP_LabAudit(labIndex)
    return "Inspecting native hack " .. (labIndex + 1) .. "/" .. count
  end)
end

local function rebuildNative()
  call(function(player)
    if not player:SDP_LabRebuildable(labIndex) then
      return "This action needs unsupported effectors/recipients or more than two statuses. Inspect its breakdown; no partial rebuild was made."
    end
    local first, second = player:SDP_LabLeaf(labIndex, 0), player:SDP_LabLeaf(labIndex, 1)
    recipe = {name="Rebuilt native core", first={4,5,0}, second={0,0,0}, nativeFirst=first}
    if second ~= "" then recipe.second={4,5,0}; recipe.nativeSecond=second end
    return "Built completion-status recipe. Upload to test; change its triggers/conditions to experiment. RAM/trace/upload timing are not reconstructed."
  end)
end

local function writeReport()
  local file = io.open("quickhack-lab-report.txt", "a")
  if not file then message = "Could not write lab report."; return end
  file:write(os.date("%Y-%m-%d %H:%M:%S"), " | build 9\n", labAudit, "\n", targetAudit, "\n\n")
  file:close()
  message = "Snapshot appended to quickhack-lab-report.txt."
end

local function saveRecipe()
  local valid, reason = recipes.validate(recipe, false)
  if not valid then message = reason; return end
  local file = io.open("prototype-recipe.json", "w")
  if not file then message = "Could not save recipe."; return end
  file:write(json.encode({version = 2, recipe = recipe}))
  file:close()
  message = "Recipe saved. Live programs and weapon bindings are session-only."
end

local function loadRecipe()
  local file = io.open("prototype-recipe.json", "r")
  if not file then message = "No saved recipe yet."; return end
  local contents = file:read("*a"); file:close()
  local ok, value = pcall(json.decode, contents)
  if not ok or type(value) ~= "table" or (value.version ~= 1 and value.version ~= 2) then message = "Saved recipe is invalid or unsupported."; return end
  local valid, reason = recipes.validate(value.recipe, false)
  if not valid then message = reason; return end
  recipe = recipes.copy(value.recipe)
  recipe.name = type(recipe.name) == "string" and recipe.name:sub(1, 64) or "Custom recipe"
  message = "Recipe loaded. Enable and upload/build to use it."
end

local function learnNative(slot)
  call(function(player)
    local leaf = player:SDP_LabLeaf(labIndex, 0)
    if leaf == "" then return "This action has no supported target-status primitive to learn." end
    local rule = slot == 1 and recipe.first or recipe.second
    if rule[1] == 0 then rule[1], rule[3] = 4, 0 end
    rule[2] = 5
    if slot == 1 then recipe.nativeFirst = leaf else recipe.nativeSecond = leaf end
    recipe.name = "Native mix"
    return "Learned " .. leaf .. " into rule " .. slot .. ". Only this status leaf was extracted; see the audit for other effects."
  end)
end

function M.init()
  print("SDP Workbench: Lua build 9 loaded")
  registerHotkey("SDPPrototypeWorkbench", "Prototype: toggle crafting workbench", function() visible = not visible end)
  registerHotkey("SDPPrototypeUpload", "Prototype: upload selected recipe to aimed enemy", upload)
  registerHotkey("SDPPrototypeSpread", "Prototype: propagate aimed enemy's program", propagate)
  registerHotkey("SDPPrototypeRearm", "Prototype: rearm aimed enemy's program for testing", rearm)
  registerHotkey("SDPNativeSpread", "Quickhack lab: spread existing native quickhack", spreadNative)
  registerHotkey("SDPInspectHack", "Quickhack lab: inspect target's active quickhacks", inspectTarget)
  registerHotkey("SDPOpticsTrace", "Quickhack lab: record aimed enemy for 30 seconds", startTrace)
end

function M.setOverlay(open) overlayOpen = open end

function M.update(delta)
  tickElapsed = tickElapsed + delta
  if tickElapsed >= 0.10 then
    tickElapsed = 0
    updateTrace()
    pcall(function() local player = Game.GetPlayer(); if player then player:SDP_PrototypeTick() end end)
  end
  elapsed = elapsed + delta
  if elapsed < 1 then return end
  elapsed = 0
  local player = Game.GetPlayer()
  if not player then status = "Load a save."; lastSpreadSequence = 0; return end
  -- No automatic enable on load: the runtime belongs to the current player object.
  local ok, result = pcall(function() return player:SDP_PrototypeStatus() end)
  status = ok and result or "Backend unavailable; deploy prototype scripts and restart."
  pcall(function()
    local sequence = player:SDP_LabSpreadSequence()
    if sequence ~= lastSpreadSequence then
      lastSpreadSequence = sequence
      if sequence > 0 then
        message = player:SDP_LabSpreadReport()
        print("SDP Workbench verification: " .. message)
      end
    end
  end)
end

local function ruleEditor(label, rule, secondary)
  ImGui.Text(label)
  if ImGui.Button(recipes.triggers[rule[1] + 1] .. "##trigger" .. label) then
    local nextTrigger = rule[1] + 1
    if nextTrigger > 5 then nextTrigger = secondary and 0 or 1 end
    rule[1] = nextTrigger
    if nextTrigger == 0 then rule[2], rule[3] = 0, 0
    elseif rule[2] == 0 then rule[2], rule[3] = 1, 0 end
  end
  if rule[1] == 0 then return end
  ImGui.SameLine()
  if ImGui.Button(recipes.payloads[rule[2]] .. "##payload" .. label) then rule[2] = rule[2] % 8 + 1 end
  if rule[2] ~= 5 then
    local duration = rule[4] or 4
    if ImGui.Button("Duration: " .. duration .. "s##" .. label) then rule[4] = ({[2]=4, [4]=8, [8]=2})[duration] end
    if rule[2] == 2 or rule[2] == 3 or rule[2] == 7 or rule[2] == 8 then
      ImGui.SameLine()
      local amount = rule[5] or 25
      if ImGui.Button("Damage: " .. amount .. "##" .. label) then rule[5] = ({[10]=25, [25]=50, [50]=10})[amount] end
      ImGui.SameLine()
      local interval = rule[6] or 1
      if ImGui.Button("Pulse: " .. interval .. "s##" .. label) then rule[6] = ({[0.5]=1, [1]=2, [2]=0.5})[interval] end
    end
  end
  if ImGui.Button(recipes.conditions[rule[3] + 1] .. "##condition" .. label) then rule[3] = (rule[3] + 1) % 3 end
end

function M.draw()
  if not visible then return end
  ImGui.SetNextWindowSize(620, 570, ImGuiCond.FirstUseEver)
  local flags = overlayOpen and 0 or (ImGuiWindowFlags.NoMouseInputs + ImGuiWindowFlags.NoNavInputs + ImGuiWindowFlags.NoNavFocus)
  if ImGui.Begin("SDP component workbench (prototype)", flags) then
    ImGui.Text("Workbench build 9 - Quickhack lab")
    ImGui.TextWrapped("Open CET to edit. Close CET, open the game scanner, highlight an enemy and press upload. Each press shows its result on screen.")
    ImGui.TextWrapped(status)
    if ImGui.Button("Enable / reset session") then enable() end
    ImGui.SameLine()
    if ImGui.Button("Disable and clear") then call(function(player) return player:SDP_PrototypeEnable(false) end) end
    ImGui.Separator()
    for i, preset in ipairs(recipes.presets) do
      if (i - 1) % 3 ~= 0 then ImGui.SameLine() end
      if ImGui.Button(preset.name) then recipe = recipes.copy(preset) end
    end
    recipe.name = ImGui.InputText("Recipe name", recipe.name, 65)
    ruleEditor("Primary rule", recipe.first, false)
    ruleEditor("Secondary rule", recipe.second, true)
    local _, reason = recipes.validate(recipe, false)
    ImGui.TextWrapped(reason)
    ImGui.TextWrapped(recipes.describe(recipe.first))
    ImGui.TextWrapped(recipes.describe(recipe.second))
    if recipe.first[2] == 5 then ImGui.TextWrapped("Primary native leaf: " .. (recipe.nativeFirst or "not selected")) end
    if recipe.second[2] == 5 then ImGui.TextWrapped("Secondary native leaf: " .. (recipe.nativeSecond or "not selected")) end
    ImGui.TextWrapped("Conditions are sampled before each event: a hit that causes blindness cannot also use that new blindness for the second rule.")
    ImGui.Separator()
    if ImGui.Button("Upload to aimed enemy") then upload() end
    ImGui.SameLine()
    if ImGui.Button("Propagate installed program") then propagate() end
    if ImGui.Button("Rearm selected program (test)") then rearm() end
    ImGui.TextWrapped("Rearm restores 30 seconds and 3 charges on an active program. If it expired, upload again. Reloads/hits detected and target status above show each stage of the test.")
    if ImGui.Button("Assemble on held gun") then bindWeapon() end
    ImGui.SameLine()
    if ImGui.Button("Save recipe") then saveRecipe() end
    ImGui.SameLine()
    if ImGui.Button("Load recipe") then loadRecipe() end
    ImGui.TextWrapped("Programs: 30 seconds, 3 charges per rule, 2-second cooldown. Propagate once to up to 3 enemies within 8m; copies cannot spread. Weapon rules have cooldowns but unlimited charges.")
    ImGui.TextWrapped("Custom durations: 2/4/8 seconds. Damage: 10/25/50 base per pulse, every 0.5/1/2 seconds; defenses can change final damage. Same payload refreshes, never stacks. Native references retain native timing. Upload and delayed rules fire once per installation/rearm. Free testing: no material/RAM costs or native queue integration yet.")
    ImGui.Separator()
    ImGui.TextWrapped(message)
    ImGui.Separator()
    ImGui.Text("Native quickhack lab")
    if ImGui.Button("Spread existing quickhack") then spreadNative() end
    ImGui.SameLine()
    if ImGui.Button("Inspect target effects") then inspectTarget() end
    if ImGui.Button("Record aimed enemy (30s)") then startTrace() end
    if traceRecording then ImGui.TextWrapped("Recording selected enemy. Upload Optics after a baseline, then move. Ends after 30 simulation seconds.") end
    if ImGui.Button("Inspect equipped hack") then inspectNative(0) end
    ImGui.SameLine()
    if ImGui.Button("Previous hack") then inspectNative(-1) end
    ImGui.SameLine()
    if ImGui.Button("Next hack") then inspectNative(1) end
    ImGui.TextWrapped(labAudit)
    if ImGui.Button("Learn first status -> primary") then learnNative(1) end
    ImGui.SameLine()
    if ImGui.Button("Learn first status -> secondary") then learnNative(2) end
    if ImGui.Button("Rebuild selected native core") then rebuildNative() end
    ImGui.SameLine()
    if ImGui.Button("Save comparison snapshot") then writeReport() end
    ImGui.TextWrapped(targetAudit)
    ImGui.TextWrapped("Native spread copies the latest supported active status, not a new upload. Rebuild uses the inspected native status leaves. Core presets use generic effects and are not tier-exact replicas.")
  end
  ImGui.End()
end

return M
