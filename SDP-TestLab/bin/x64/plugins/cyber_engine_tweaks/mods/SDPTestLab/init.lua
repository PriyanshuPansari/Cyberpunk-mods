-- SDP TestLab: a CET control panel for the independent redscript test controller.
-- It never drives Combat Arena's survival director or restores a player baseline.
local M = {}
local visible, overlay = true, false
local elapsed, selected = 0, 0
local playerKey, queuedStart = nil, nil
local scenarioNames, scenarioSummary = {}, ""
local state, status, report = 0, "Load a test save to connect to SDP TestLab.", ""
local message, baseline, notes = "", "", ""
local connected, lastTerminal = false, nil
local lastError = ""
local stateNames = { [0] = "Idle", "Site inspection", "Preparing actors", "Ready", "Running", "Finished", "Failed" }
local reportFile = "testlab-reports.jsonl"

local function fail(context, err)
  message = context .. ": " .. tostring(err)
  if message ~= lastError then print("SDP TestLab: " .. message); lastError = message end
end

local function player()
  local ok, result = pcall(function() return Game.GetPlayer() end)
  return ok and result or nil
end

local function identity(value)
  if not value then return nil end
  local ok, result = pcall(function() return tostring(value:GetEntityID().hash) end)
  return ok and result or tostring(value)
end

local function exportSnapshot(kind)
  if not connected or report == "" then message = "No controller report is available."; return false end
  local parsed, detail = pcall(json.decode, report)
  local row = {
    schema = 1, source = "SDPTestLab.CET", kind = kind or "snapshot",
    captured_utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    operator_baseline = baseline, operator_notes = notes,
    controller_state = state, controller_status = status,
  }
  if parsed and type(detail) == "table" then
    row.controller = detail
  else
    row.controller_report_raw = report
    row.controller_report_parse_error = tostring(detail)
  end
  local encoded, output = pcall(json.encode, row)
  if not encoded then fail("Cannot encode report", output); return false end
  local file, errorText = io.open(reportFile, "a")
  if not file then fail("Cannot open report file", errorText); return false end
  local wrote, writeError = file:write(output .. "\n")
  local closed, closeError = file:close()
  if not wrote or not closed then fail("Cannot write report", writeError or closeError); return false end
  message = "Appended " .. kind .. " to " .. reportFile .. "."
  return true
end

local function disconnect()
  connected, queuedStart, playerKey = false, nil, nil
  state, report, scenarioNames, scenarioSummary = 0, "", {}, ""
  lastTerminal = nil
  status = "Load a test save to connect to SDP TestLab."
end

local function refresh()
  local value = player()
  if not value then disconnect(); return nil end
  local key = identity(value)
  if key ~= playerKey then
    queuedStart, lastTerminal = nil, nil
    playerKey, scenarioNames = key, {}
  end
  local ok, err = pcall(function()
    state = tonumber(value:SDPTL_State())
    status = tostring(value:SDPTL_Status())
    report = tostring(value:SDPTL_Report())
    local count = tonumber(value:SDPTL_ScenarioCount()) or 0
    if count < 1 or count > 100 then error("No valid scenario catalog returned by redscript.") end
    if #scenarioNames ~= count then
      scenarioNames = {}
      for index = 0, count - 1 do scenarioNames[index + 1] = tostring(value:SDPTL_ScenarioName(index)) end
    end
    selected = math.max(0, math.min(count - 1, selected))
    scenarioSummary = tostring(value:SDPTL_ScenarioSummary(selected))
  end)
  if not ok then
    connected, queuedStart = false, nil
    status = "Controller unavailable. Check the redscript compilation log and matching SDP TestLab scripts."
    fail("Controller read failed", err)
    return nil
  end
  connected = true
  -- A terminal state is exported once. An explicit restart/prepare re-arms this.
  if state == 5 or state == 6 then
    if lastTerminal ~= state then
      if exportSnapshot(state == 5 and "finished" or "failed") then lastTerminal = state end
    end
  else
    lastTerminal = nil
  end
  return value
end

local function command(id)
  local value = refresh()
  if not value then return false end
  queuedStart = nil
  if id == 3 or id == 5 or id == 9 then exportSnapshot("before_cleanup") end
  local ok, err = pcall(function() value:SDPTL_Command(id, selected) end)
  if not ok then fail("Controller command failed", err); return false end
  refresh()
  return true
end

local function startReady()
  local value = refresh()
  if not value then return end
  local ok, ready = pcall(function() return value:SDPTL_Ready() end)
  if not ok or not ready or state ~= 3 then message = "Prepare and qualify a scenario before starting."; return end
  if overlay then
    queuedStart = { player = playerKey, scenario = selected }
    message = "Start armed. Close the CET overlay to begin, or cancel below."
  else
    command(2)
  end
end

local function closeOverlay()
  overlay = false
  local pending = queuedStart
  queuedStart = nil
  if not pending then return end
  local value = refresh()
  if not value or pending.player ~= playerKey or pending.scenario ~= selected or state ~= 3 then
    message = "Armed start cancelled because the player or scenario changed."
    return
  end
  command(2)
end

local function draw()
  if not visible or not overlay then return end
  ImGui.SetNextWindowSize(720, 690, ImGuiCond.FirstUseEver)
  if ImGui.Begin("SDP TestLab") then
    ImGui.Text("Base-game overhaul test scenarios")
    ImGui.TextWrapped(status)
    if message ~= "" then ImGui.TextWrapped(message) end
    if connected then
      ImGui.Text("State: " .. (stateNames[state] or tostring(state)))
      ImGui.Separator()
      if state == 0 or state == 5 or state == 6 then
        local nextSelection, changed = ImGui.Combo("Scenario", selected, scenarioNames, #scenarioNames)
        if changed then selected = nextSelection; queuedStart = nil; refresh() end
      else
        ImGui.Text("Selected: " .. (scenarioNames[selected + 1] or "unknown"))
      end
      ImGui.TextWrapped(scenarioSummary)
      ImGui.TextWrapped("Each preset requires in-game qualification. Fixed spawn requests do not prove navigation, cover, equipment or netrunner eligibility.")
      if state == 0 or state == 5 or state == 6 then
        if ImGui.Button("Prepare selected scenario") then command(1) end
      end
      if state == 1 then
        ImGui.TextWrapped("Inspect the destination floor, route, cover and return position. Confirm only when the site is usable.")
        if ImGui.Button("Confirm inspected site / spawn actors") then command(7) end
      end
      if state == 3 then
        if queuedStart then
          if ImGui.Button("Cancel armed start") then queuedStart = nil; message = "Armed start cancelled." end
        elseif ImGui.Button("Arm start (close CET to begin)") then startReady() end
      end
      if state == 4 then ImGui.TextWrapped("Test is running. Close CET for gameplay; opening the overlay may affect timing.") end
      if state == 5 or state == 6 then
        if ImGui.Button("Repeat actor setup") then command(4) end
      end
      if state ~= 0 then
        if ImGui.Button("Abort / remove test actors") then command(3) end
        ImGui.SameLine()
      end
      if ImGui.Button("Clean up and return to origin") then command(5) end
      ImGui.Separator()
      if state == 0 then
        if ImGui.Button("Record current site coordinates") then command(6); exportSnapshot("site_survey") end
        if ImGui.Button("Observe native encounter here") then command(8) end
        ImGui.TextWrapped("Native-site observation does not spawn actors or create security-network membership.")
      end
      ImGui.TextWrapped("Restarting actors does not reset HP, RAM, armor integrity, injuries, ammunition, effects or progression. Reload a declared test-save baseline between balance comparisons. Normal death is enabled.")
      ImGui.Separator()
      baseline = ImGui.InputText("Baseline / save / build", baseline, 241)
      notes = ImGui.InputText("Observation / qualification notes", notes, 1001)
      if ImGui.Button("Append report snapshot") then refresh(); exportSnapshot("snapshot") end
      ImGui.TextWrapped("Reports: CET mods/SDPTestLab/" .. reportFile .. ". Controller reports and operator notes are exported; this panel does not independently measure projectile hits or AI decisions.")
    end
  end
  ImGui.End()
end

registerHotkey("SDPTestLabPanel", "SDP TestLab: toggle control panel (CET overlay)", function()
  visible = not visible
end)
registerHotkey("SDPTestLabStart", "SDP TestLab: start prepared test", startReady)
registerHotkey("SDPTestLabAbort", "SDP TestLab: abort / clean up actors", function() command(3) end)
registerForEvent("onInit", refresh)
registerForEvent("onOverlayOpen", function() overlay = true; refresh() end)
registerForEvent("onOverlayClose", closeOverlay)
registerForEvent("onUpdate", function(delta)
  elapsed = elapsed + delta
  if elapsed >= 0.5 then elapsed = 0; refresh() end
end)
registerForEvent("onDraw", function()
  local ok, err = pcall(draw)
  if not ok then fail("Panel drawing failed", err) end
end)
registerForEvent("onShutdown", function()
  queuedStart = nil
  if connected and state ~= 0 then command(9) end
end)

-- Small public API is also used by the isolated CET lifecycle tests.
M.command, M.refresh, M.startReady, M.exportSnapshot = command, refresh, startReady, exportSnapshot
return M
