"""Execute the real Lua workbench/catalog under LuaJIT (CET's Lua dialect).

Install lupa into .stage/prototype-test-deps or the active Python environment.
These tests cover authoring and bridge behavior, not Cyberpunk combat execution.
Compile the redscript separately; run docs/PROTOTYPE_CRAFTING.md in-game cases.
"""
import os
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".stage/prototype-test-deps"))
from lupa.luajit21 import LuaRuntime

MOD = ROOT / "bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting"
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().module_path = MOD.as_posix() + "/?.lua"
lua.execute("package.path = module_path .. ';' .. package.path")
test_script = r'''
local recipes = require("prototype_recipes")
assert(_VERSION == "Lua 5.1")
for _, preset in ipairs(recipes.presets) do assert(recipes.validate(preset, false)) end
assert(not recipes.validate(recipes.presets[1], true)) -- opponent reload is program-only
assert(recipes.validate(recipes.presets[2], true))
assert(recipes.validate(recipes.presets[3], true))
local copy = recipes.copy(recipes.presets[1])
copy.first[1] = 2
assert(recipes.presets[1].first[1] == 1, "Editing a build mutated its preset")
local function bad(a, b)
  assert(not recipes.validate({first = a, second = b}, false))
end
bad({0,0,0}, {0,0,0})
bad({1,1,0}, {1,1,0})
bad({2,2,1}, {2,2,2}) -- complexity 14
bad({1,1,0}, {0,1,0}) -- disabled rules must be canonical
bad({6,1,0}, {0,0,0})
bad({1,9,0}, {0,0,0})
bad({4,5,0}, {0,0,0}) -- native payload requires a learned status ID
bad({1,1,-1}, {0,0,0})
bad({1.5,1,0}, {0,0,0})
bad({"1",1,0}, {0,0,0})
bad({0/0,1,0}, {0,0,0})
bad({4,2,0,0}, {0,0,0})
bad({4,2,0,4,9999}, {0,0,0})
bad({4,2,0,4,25,0}, {0,0,0})
bad({4,2,0,4,25,0/0}, {0,0,0})
local tuned = recipes.copy({first={4,2,0,8,50,0.5}, second={0,0,0}})
assert(tuned.first[4] == 8 and tuned.first[5] == 50 and tuned.first[6] == 0.5)
assert(recipes.validate(tuned))
assert(recipes.copy(recipes.presets[1]).first[4] == 4)
assert(not recipes.validate(nil))
assert(not recipes.validate({}))
assert(recipes.validate({first={2,2,0}, second={3,2,1}}, true)) -- complexity 11
assert(recipes.validate({first={2,2,0}, second={2,1,1}}, true)) -- exactly 12
print("PASS: presets, independent editing, budget boundary and malformed recipes")

hotkeys, calls = {}, {enable=0, assemble=0, upload=0, spread=0, bind=0, rearm=0}
local player = {}
local enabled = false
local rejectAssemble = false
local playerAvailable = true
local recordsAvailable = true
local backendVersion = 9
local nativeAccepted, rebuildable = true, true
local parametersAccepted = true
local spreadSequence = 0
local buttons = {}
local beginDepth = 0
local capturedText = {}
function registerHotkey(id, _, callback)
  assert(not hotkeys[id], "Duplicate hotkey")
  hotkeys[id] = callback
end
function player:SDP_PrototypeEnable(value)
  calls.enable = calls.enable + 1
  enabled = value
  return value and "Enabled" or "Disabled"
end
function player:SDP_PrototypeAssemble(t1,p1,c1,t2,p2,c2)
  calls.assemble = calls.assemble + 1
  assert(recipes.validate({first={t1,p1,c1},second={t2,p2,c2},nativeFirst="mock-first",nativeSecond="mock-second"}))
  if not enabled or rejectAssemble then return "Rejected" end
  return "Recipe assembled. Upload it or bind it to your held gun."
end
function player:SDP_PrototypeUpload() calls.upload = calls.upload + 1; return "Uploaded" end
function player:SDP_PrototypePropagate() calls.spread = calls.spread + 1; return "Spread" end
function player:SDP_PrototypeBindWeapon() calls.bind = calls.bind + 1; return "Bound" end
function player:SDP_PrototypeStatus() return enabled and "Enabled" or "Disabled" end
function player:SDP_PrototypeVersion() return backendVersion end
function player:SDP_PrototypeRearm() calls.rearm = calls.rearm + 1; return "Rearmed" end
function player:SDP_PrototypeTick() end
local traceDrains = 0
function player:SDP_OpticsTraceStart()
  calls.traceStarts = (calls.traceStarts or 0) + 1
  return "Recording started: test"
end
function player:SDP_OpticsTraceDrain()
  traceDrains = traceDrains + 1
  return traceDrains == 1 and "0 START npc=test\n0 SAMPLE blind=no visible=yes\n" or "30 END dropped=0\n"
end
function player:SDP_PrototypeConfigure(slot, duration, amount, interval)
  calls.configured = {slot, duration, amount, interval}
  return parametersAccepted
end
function player:SDP_PrototypeSetNative(slot, id) return nativeAccepted end
function player:SDP_LabCount() return 2 end
function player:SDP_LabAudit(index) return "Native audit " .. index end
function player:SDP_LabRebuildable(index) return rebuildable end
function player:SDP_LabLeaf(index, leaf) return leaf == 0 and (index == 0 and "BaseStatusEffect.TestOptics" or "BaseStatusEffect.TestOverheat") or "" end
function player:SDP_LabSpreadNative() calls.nativeSpread = (calls.nativeSpread or 0) + 1; return "Native spread" end
function player:SDP_LabInspectTarget() return "Target snapshot" end
function player:SDP_LabSpreadSequence() return spreadSequence end
function player:SDP_LabSpreadReport() return "2/3 recipients have the copied status" end
local notifications = {}
function player:SDP_PrototypeNotify(text) notifications[#notifications+1] = text end
Game = {GetPlayer = function() return playerAvailable and player or nil end}
TweakDBID = {new=function(id) return id end}
TweakDB = {GetRecord = function() return recordsAvailable and {} or nil end}
ImGuiCond = {FirstUseEver=1}
ImGuiWindowFlags = {NoMouseInputs=1, NoNavInputs=2, NoNavFocus=4}
ImGui = {
  SetNextWindowSize = function() end,
  Begin = function() beginDepth = beginDepth + 1; return true end,
  End = function() beginDepth = beginDepth - 1 end,
  Text = function() end,
  TextWrapped = function(value) capturedText[#capturedText+1] = value end,
  Separator = function() end,
  SameLine = function() end,
  InputText = function(_, value) return value end,
  Button = function(label)
    if buttons[label] then buttons[label] = nil; return true end
    return false
  end,
}
-- Round-trip codec stub isolates file persistence from CET's JSON dependency.
local saved
json = {encode=function(value) saved=value; return "saved" end,
        decode=function(text) if text ~= "saved" then error("Malformed JSON") end; return saved end}
local workbench = require("prototype")
workbench.init()
workbench.update(1)
assert(calls.enable == 0, "Workbench auto-enabled")
backendVersion = 2
hotkeys.SDPPrototypeUpload()
assert(calls.assemble == 0 and calls.upload == 0, "Outdated backend accepted an action")
assert(notifications[#notifications]:find("Build mismatch"), "Version mismatch lacked feedback")
backendVersion = 9
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 0, "Failed assembly uploaded a stale build")
assert(notifications[#notifications] == "Rejected", "Rejection was not shown on screen")
hotkeys.SDPPrototypeWorkbench() -- mismatch made it visible; close and reopen to test binding
hotkeys.SDPPrototypeWorkbench()
workbench.setOverlay(true)
local function click(label)
  buttons[label] = true
  workbench.draw()
  assert(not buttons[label], "Button not rendered: " .. label)
  assert(beginDepth == 0, "Unbalanced ImGui Begin/End")
end
recordsAvailable = false
click("Enable / reset session")
assert(calls.enable == 0, "Enabled without payload records")
recordsAvailable = true
click("Enable / reset session")
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 1)
assert(notifications[#notifications] == "Uploaded", "Upload feedback was not shown")
hotkeys.SDPPrototypeSpread()
assert(calls.spread == 1)
hotkeys.SDPPrototypeRearm()
hotkeys.SDPPrototypeRearm()
assert(calls.rearm == 2 and notifications[#notifications] == "Rearmed", "Rearm was not repeatable")
click("Assemble on held gun")
assert(calls.bind == 0, "Bound an opponent-reload rule to a weapon")
click("Blackout Gun")
click("Assemble on held gun")
assert(calls.bind == 1)
rejectAssemble = true
click("Assemble on held gun")
hotkeys.SDPPrototypeUpload()
assert(calls.bind == 1 and calls.upload == 1, "Backend rejection used stale recipe")
rejectAssemble = false
parametersAccepted = false
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 1, "Rejected parameters uploaded a partial recipe")
parametersAccepted = true
click("Save recipe")
click("Heat Response")
click("Load recipe")
assert(saved.recipe.name == "Blackout Gun")
-- Use every rule editor control, including cycling the secondary rule off/on.
click("Your ranged headshot##triggerSecondary rule")
click("On upload##triggerSecondary rule")
click("After 3 seconds##triggerSecondary rule")
click("Off##triggerSecondary rule")
click("Blindness##payloadSecondary rule")
click("Always##conditionSecondary rule")
local f=assert(io.open("prototype-recipe.json", "w")); f:write("bad"); f:close()
click("Load recipe") -- malformed saves are handled without throwing
click("Inspect equipped hack")
click("Next hack")
click("Previous hack")
rebuildable = false
click("Rebuild selected native core")
rebuildable = true
click("Rebuild selected native core")
click("Next hack")
click("Learn first status -> secondary")
nativeAccepted = false
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 1, "Missing native record uploaded a stale/partial recipe")
nativeAccepted = true
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 2)
hotkeys.SDPNativeSpread()
spreadSequence = 1
workbench.update(1)
workbench.update(1)
assert(calls.nativeSpread == 1, "Receipt polling repeated the spread action")
hotkeys.SDPInspectHack()
click("Save comparison snapshot")
assert(calls.nativeSpread == 1)
local reportFile = assert(io.open("quickhack-lab-report.txt", "r"))
local report = reportFile:read("*a"); reportFile:close()
assert(report:find("Target snapshot") and report:find("Native audit"))
click("Save recipe")
click("Heat Response")
click("Load recipe")
assert(saved.recipe.nativeFirst == "BaseStatusEffect.TestOptics", "Native component lost in saved blueprint")
assert(saved.recipe.nativeSecond == "BaseStatusEffect.TestOverheat", "Mixed secondary native component lost")
click("Thermal core")
click("Duration: 4s##Primary rule")
click("Damage: 25##Primary rule")
click("Pulse: 1s##Primary rule")
click("Save recipe")
assert(saved.version == 2)
assert(saved.recipe.first[4] == 8 and saved.recipe.first[5] == 50 and saved.recipe.first[6] == 2,
  "Primitive editor parameters did not survive saving")
click("Optics core")
click("Load recipe")
click("Save recipe")
assert(saved.recipe.first[4] == 8 and saved.recipe.first[5] == 50 and saved.recipe.first[6] == 2,
  "Primitive parameters did not survive loading")
click("Disable and clear")
assert(not enabled)
hotkeys.SDPOpticsTrace()
hotkeys.SDPOpticsTrace()
assert(calls.traceStarts == 1, "Repeated recording overwrote an active trace")
workbench.update(0.25)
workbench.update(0.25)
workbench.update(0.25)
assert(traceDrains == 2, "Finished trace kept polling")
local traceFile = assert(io.open("optics-runtime.log", "r"))
local traceText = traceFile:read("*a"); traceFile:close()
assert(traceText:find("SAMPLE blind=no visible=yes", 1, true) and traceText:find("END dropped=0", 1, true))
playerAvailable = false
hotkeys.SDPPrototypeUpload()
hotkeys.SDPPrototypeSpread()
workbench.update(1)
assert(calls.upload == 2 and calls.spread == 1)
workbench.setOverlay(false)
workbench.draw()
assert(beginDepth == 0)
print("PASS: opt-in, missing records/player, rejected assembly, weapon gating, editing and recipe files")
'''

with tempfile.TemporaryDirectory(prefix="sdp-workbench-", dir=ROOT / ".stage") as temp:
    assert Path(temp).resolve().is_relative_to(ROOT / ".stage")
    previous = os.getcwd()
    try:
        os.chdir(temp)
        lua.execute(test_script)
    finally:
        os.chdir(previous)

# Ensure adding the workbench did not replace the existing CET event owners.
source = (MOD / "init.lua").read_text(encoding="utf-8")
for event in ("onDraw", "onUpdate", "onOverlayOpen", "onOverlayClose"):
    assert source.count(f'registerForEvent("{event}",') == 1, event
for path in MOD.glob("*.lua"):
    lua.execute("assert(loadstring(...))", path.read_text(encoding="utf-8"))
print("PASS: all CET files parse under LuaJIT; event handlers remain single-owner")
