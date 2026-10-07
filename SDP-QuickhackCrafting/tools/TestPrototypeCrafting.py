"""Execute the real Lua designer, design model and lab under LuaJIT (CET's Lua dialect).

Install lupa into .stage/prototype-test-deps or the active Python environment.
These tests cover authoring and bridge behavior, not Cyberpunk combat execution.
Compile the redscript separately; run the in-game checks in docs/QUICKHACK_DESIGNER.md
and docs/PROTOTYPE_CRAFTING.md.
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
bad({1,13,0}, {0,0,0})
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
-- Build 12 payloads: immobilize/jam cost 3, deafen/cyberware 2 (SDPPrototypeRuntime.Cost).
assert(recipes.ruleCost({4,9,0}) == 4 and recipes.ruleCost({4,10,0}) == 4)
assert(recipes.ruleCost({4,11,0}) == 3 and recipes.ruleCost({4,12,1}) == 4)
print("PASS: presets, independent editing, budget boundary and malformed recipes")

local designs = require("quickhack_designs")
local starters = designs.starters()
assert(#starters >= 10, "Starter designs missing")
for _, design in ipairs(starters) do
  assert(designs.validate(design), design.name)
  assert(design.first[2] ~= 5 and design.second[2] ~= 5, "Starter used a native reference payload")
end
local optics = designs.new("Optics")
assert(designs.validate(optics))
-- Signature format is mirrored by SDPQHDesign.RuleSignature in CustomPrograms.reds.
assert(designs.signature(optics) == "4.1.0.2.2.2|0|2|0", designs.signature(optics))
local st = designs.stats(optics)
assert(st.complexity == 3 and st.points == 5 and st.ram == 4 and st.uploadTenths == 8 and st.cooldown == 14, "Optics stats")
assert(designs.uploadText(st) == "0.8s")
local heavy = {name="Heavy", first={2,2,1,8,50,0.5}, second={2,3,2,8,50,0.5}, lifetime=60, spread=3}
assert(not designs.validate(heavy), "Complexity above 12 was accepted")
heavy.first = {4,2,0,8,50,0.5}
heavy.second = {3,3,2,8,50,0.5}
assert(designs.validate(heavy))
st = designs.stats(heavy)
-- complexity 4 + 5, params 6 + 6, spread 6, lifetime 2 => 29 points
assert(st.complexity == 9 and st.points == 29, "Heavy points " .. st.points)
assert(st.ram == 16 and st.cooldown == 62 and st.uncommon == 29 and st.rare == 8, "Heavy derived stats")
assert(designs.signature(heavy) == "4.2.0.3.3.3|3.3.2.3.3.3|3|3")
for _, payload in ipairs({9, 10, 11, 12}) do
  local d = designs.new("New payload " .. payload); d.first[2] = payload
  assert(designs.validate(d), "Build 12 payload rejected: " .. payload)
  assert(designs.describe(d):find(designs.payloadText[payload], 1, true))
end
local native = designs.copy(optics); native.first[2] = 5
assert(not designs.validate(native), "Native reference payload compiled")
assert(not designs.validate({name="", first={4,1,0,4,25,1}, second={0,0,0,4,25,1}, lifetime=30, spread=0}))
assert(not designs.validate({name="x", first={4,1,0,4,25,1}, second={0,0,0,4,25,1}, lifetime=45, spread=0}))
assert(not designs.validate({name="x", first={4,1,0,4,25,1}, second={0,0,0,4,25,1}, lifetime=30, spread=4}))
assert(not designs.validate({name="x", first={4,1,0,4,25,1}, second={0,0,0,4,25,1}, lifetime=30, spread=1.5}))
-- Over-budget drafts stay in the library; malformed entries do not.
local draft = {name="Draft", first={2,2,1,4,25,1}, second={2,3,2,4,25,1}, lifetime=30, spread=0}
assert(designs.wellFormed(draft) and not designs.validate(draft))
local list, skipped = designs.decode({version=1, designs={draft, optics, {name="bad", first={9,1,0}, second={0,0,0}}, "junk"}})
assert(#list == 2 and skipped == 2, "Library sanitize")
assert(list[1].id == 1 and list[2].id == 2)
local legacy = designs.decode({version=2, recipe={name="Old", first={1,1,0,4,25,1}, second={3,2,1,4,25,1}}})
assert(#legacy == 1 and legacy[1].lifetime == 30 and legacy[1].spread == 0, "Legacy blueprint import")
assert(designs.decode({version=7}) == nil)
local encoded = designs.encode(list)
assert(encoded.version == 1 and encoded.designs[2].name == "Optics" and encoded.designs[2].id == nil)
assert(designs.findBySignature(list, "4.1.0.2.2.2|0|2|0").name == "Optics")
assert(designs.findBySignature(list, "nope") == nil)
assert(designs.uniqueName(list, "Optics") == "Optics 2" and designs.uniqueName(list, "Fresh") == "Fresh")
assert(designs.describe(heavy):find("spreads to 3 nearby enemies", 1, true))
assert(designs.describe(optics):find("On upload: blindness for 4s.", 1, true))
print("PASS: design model, cost model, signatures, library sanitize and legacy import")

hotkeys, calls = {}, {enable=0, assemble=0, upload=0, spread=0, bind=0, rearm=0, compile={}, labels={}, fabricate=0, clear=0}
local player = {}
local enabled = false
local rejectAssemble = false
local playerAvailable = true
local recordsAvailable = true
local backendVersion = 13
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
-- Mock of the save's design library (DesignLibrary.reds): 16 values per design.
local slotSignatures, slotNames = {"", "", "", ""}, {}
local lib, libRevision = {}, 7
local function toValues(d)
  local a, b = d.first, d.second
  return {1, designs.indexOf(designs.lifetimes, d.lifetime), d.spread, a[1], a[2], a[3], a[4], a[5], a[6],
    b[1], b[2], b[3], b[4], b[5], b[6], 0}
end
local function fromValues(name, v)
  return {name = name, lifetime = designs.lifetimes[v[2]], spread = v[3],
    first = {v[4], v[5], v[6], v[7], v[8], v[9]}, second = {v[10], v[11], v[12], v[13], v[14], v[15]}}
end
local function store(index, name, values)
  libRevision = libRevision + 1
  if index < 0 or index >= #lib then lib[#lib + 1] = {name = name, v = values}; return #lib - 1 end
  lib[index + 1] = {name = name, v = values}
  return index
end
for _, d in ipairs(designs.starters()) do store(-1, d.name, toValues(d)) end
function player:SDPQH_LibraryRevision() return libRevision end
function player:SDPQH_DesignCount() return #lib end
function player:SDPQH_DesignName(i) return lib[i + 1].name end
function player:SDPQH_DesignField(i, k) return lib[i + 1].v[k + 1] end
function player:SDPQH_SaveDesign(i, name, t1,p1,c1,d1,a1,i1, t2,p2,c2,d2,a2,i2, life, spread)
  calls.saves = (calls.saves or 0) + 1
  return store(i, name, toValues({first={t1,p1,c1,d1,a1,i1}, second={t2,p2,c2,d2,a2,i2}, lifetime=life, spread=spread}))
end
function player:SDPQH_NewDesign() local d = designs.new("New design " .. (#lib + 1)); return store(-1, d.name, toValues(d)) end
function player:SDPQH_DuplicateDesign(i) return store(-1, lib[i + 1].name .. " copy", {unpack(lib[i + 1].v)}) end
function player:SDPQH_DeleteDesign(i) libRevision = libRevision + 1; table.remove(lib, i + 1); return true end
function player:SDPQH_AddStarters() return 0 end
function player:SDPQH_OpenDesignerMenu() calls.openMenu = (calls.openMenu or 0) + 1; return "Opening" end
function player:SDPQH_EnsureApplied() calls.applied = (calls.applied or 0) + 1 end
function player:SDPQH_Components() return "12 uncommon, 1 rare quickhack components" end
function player:SDPQH_SlotStatus(slot) return slotSignatures[slot] == "" and "Blank" or "Compiled" end
function player:SDPQH_SlotSignature(slot) return slotSignatures[slot] end
function player:SDPQH_SlotName(slot) return slotNames[slot] or ("Blank program " .. slot) end
function player:SDPQH_CompileDesign(slot, index, free)
  local entry = lib[index + 1]
  calls.compile[#calls.compile + 1] = {slot = slot, index = index, free = free}
  slotSignatures[slot] = designs.signature(fromValues(entry.name, entry.v))
  slotNames[slot] = entry.name
  return "Compiled into program " .. slot
end
function player:SDPQH_FabricateChip(slot, free) calls.fabricate = calls.fabricate + 1; calls.fabricateFree = free; return "Chip " .. slot end
function player:SDPQH_ClearSlot(slot) calls.clear = calls.clear + 1; slotSignatures[slot] = ""; slotNames[slot] = nil; return "Cleared" end
function player:SDPQH_RecordCheck() return "Program records A: ok" end
-- Native reference catalog (NativeReferences.reds) and comparison meter.
local refTitles = {"Overheat T1", "Overheat T3", "Ping T1"}
local refCoverage = {"recreated", "recreated", "native only"}
function player:SDPQH_RefRefresh() calls.refRefresh = (calls.refRefresh or 0) + 1; return #refTitles end
function player:SDPQH_RefCount() return #refTitles end
function player:SDPQH_RefTitle(i) return refTitles[i + 1] end
function player:SDPQH_RefCoverage(i) return refCoverage[i + 1] end
function player:SDPQH_RefSummary(i) return "Summary of " .. refTitles[i + 1] end
function player:SDPQH_CompileReference(slot, i) calls.refCompile = {slot, i}; return "Program now recreates " .. refTitles[i + 1] end
function player:SDPQH_RefToLibrary(i)
  calls.refApprox = i
  local d = designs.new(refTitles[i + 1] .. " approx"); d.first[2] = 2
  return store(-1, d.name, toValues(d))
end
function player:SDPQH_RefGiveNative(i) calls.refGive = i; return refTitles[i + 1] .. " added" end
function player:SDPQH_DumpHeader() return "SDP native quickhack dump | build 13\n\n" end
function player:SDPQH_RefDump(i) calls.dumped = (calls.dumped or 0) + 1; return "=== " .. refTitles[i + 1] .. "\n" end
local meter = "Nothing measured yet."
function player:SDPQH_MeterReport() return meter end
function player:SDPQH_MeterClear() calls.meterClear = (calls.meterClear or 0) + 1; return "Comparison meter cleared." end
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
local combos, checks, selects, inputs = {}, {}, {}, {}
local childDepth, tabBarDepth, tabDepth = 0, 0, 0
ImGui = {
  SetNextWindowSize = function() end,
  Begin = function() beginDepth = beginDepth + 1; return true end,
  End = function() beginDepth = beginDepth - 1 end,
  Text = function(value) capturedText[#capturedText+1] = value end,
  TextWrapped = function(value) capturedText[#capturedText+1] = value end,
  TextColored = function(_, _, _, _, value) capturedText[#capturedText+1] = value end,
  Separator = function() end,
  SameLine = function() end,
  ProgressBar = function(fraction) assert(fraction >= 0 and fraction <= 1) end,
  InputText = function(label, value)
    if inputs[label] then local v = inputs[label]; inputs[label] = nil; return v, true end
    return value, false
  end,
  Button = function(label)
    if buttons[label] then buttons[label] = nil; return true end
    return false
  end,
  Combo = function(label, index, items, count)
    assert(count == #items and index >= 0 and index < count, "Combo index out of range: " .. label)
    if combos[label] then local v = combos[label]; combos[label] = nil; return v, true end
    return index, false
  end,
  Checkbox = function(label, value)
    if checks[label] ~= nil then local v = checks[label]; checks[label] = nil; return v, true end
    return value, false
  end,
  Selectable = function(label)
    if selects[label] then selects[label] = nil; return true end
    return false
  end,
  BeginChild = function() childDepth = childDepth + 1; return true end,
  EndChild = function() childDepth = childDepth - 1 end,
  BeginTabBar = function() tabBarDepth = tabBarDepth + 1; return true end,
  EndTabBar = function() tabBarDepth = tabBarDepth - 1 end,
  BeginTabItem = function() tabDepth = tabDepth + 1; return true end,
  EndTabItem = function() tabDepth = tabDepth - 1 end,
}
-- Round-trip codec stub isolates file persistence from CET's JSON dependency.
local saved
local store, encodes = {}, 0
json = {encode=function(value) encodes = encodes + 1; saved = value; store["json#" .. encodes] = value; return "json#" .. encodes end,
        decode=function(text) if not store[text] then error("Malformed JSON") end; return store[text] end}
local workbench = require("prototype")
local designer = require("designer")
workbench.init()
designer.init(workbench)
workbench.update(1)
assert(calls.enable == 0, "Workbench auto-enabled")
backendVersion = 2
hotkeys.SDPPrototypeUpload()
assert(calls.assemble == 0 and calls.upload == 0, "Outdated backend accepted an action")
assert(notifications[#notifications]:find("Build mismatch"), "Version mismatch lacked feedback")
backendVersion = 13
hotkeys.SDPPrototypeUpload()
assert(calls.upload == 0, "Failed assembly uploaded a stale build")
assert(notifications[#notifications] == "Rejected", "Rejection was not shown on screen")
hotkeys.SDPPrototypeWorkbench() -- mismatch made it visible; close and reopen to test binding
hotkeys.SDPPrototypeWorkbench()
workbench.setOverlay(true)
local function draw()
  designer.draw()
  assert(beginDepth == 0 and childDepth == 0 and tabBarDepth == 0 and tabDepth == 0, "Unbalanced ImGui Begin/End")
end
local function click(label)
  buttons[label] = true
  draw()
  assert(not buttons[label], "Button not rendered: " .. label)
end
local function pick(kind, label, value)
  kind[label] = value
  draw()
  assert(kind[label] == nil, "Control not rendered: " .. label)
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
print("PASS: lab opt-in, missing records/player, rejected assembly, weapon gating, editing and recipe files")

-- Designer: the CET window mirrors the save's library (mocked above).
local function libIndex(name)
  for i, entry in ipairs(lib) do if entry.name == name then return i end end
end
designer.update(1)
pick(selects, "Optics core##design" .. libIndex("Optics core"), true)
local before = #lib
click("New")
assert(#lib == before + 1, "New did not reach the backend")
inputs["Name"] = "Glass Jaw"
draw()
pick(combos, "Trigger##Primary rule", 2)      -- headshot
pick(combos, "Effect##Primary rule", 1)        -- thermal pulses
pick(combos, "Damage##Primary rule", 2)        -- 50
pick(combos, "Pulse##Primary rule", 0)         -- every 2s
pick(checks, "Use a second rule##Secondary rule", true)
pick(combos, "Trigger##Secondary rule", 0)     -- opponent reload
pick(combos, "Effect##Secondary rule", 3)      -- stun
pick(combos, "Lifetime", 2)                    -- 60s
pick(combos, "Spread on upload", 1)            -- 1 enemy
designer.update(0.6)                           -- debounced push to the save
local glass = lib[libIndex("Glass Jaw")]
assert(glass, "Edited design did not reach the save")
local g = fromValues(glass.name, glass.v)
assert(g.first[1] == 3 and g.first[2] == 2 and g.first[5] == 50 and g.first[6] == 2, "Primary rule edits")
assert(g.second[1] == 1 and g.second[2] == 4 and g.lifetime == 60 and g.spread == 1, "Secondary/program edits")
designer.update(1)                             -- re-reads the library after the revision change
click("B##compile")
local compiled = calls.compile[#calls.compile]
assert(compiled.slot == 2 and compiled.index == libIndex("Glass Jaw") - 1 and compiled.free == false, "Compile by design index")
designer.update(1)
local seen = false
for _, text in ipairs(capturedText) do if text == "Program B: Glass Jaw" then seen = true end end
capturedText = {}
draw()
for _, text in ipairs(capturedText) do if text == "Program B: Glass Jaw" then seen = true end end
assert(seen, "Slot name not shown from the save")
pick(checks, "Free mode (testing: no component costs)", true)
click("Fabricate chip (free)##B")
assert(calls.fabricate == 1 and calls.fabricateFree == true)
click("Edit design##B")
click("Clear slot##B")
assert(calls.clear == 1)
click("Check program records")
-- Over-budget designs are kept as drafts but cannot be compiled.
pick(combos, "Trigger##Primary rule", 1)       -- ranged hit
pick(combos, "Condition##Primary rule", 1)
pick(combos, "Trigger##Secondary rule", 1)
pick(combos, "Effect##Secondary rule", 2)
pick(combos, "Condition##Secondary rule", 2)
local compiles = #calls.compile
click("A##compile")
assert(#calls.compile == compiles, "Invalid design was compiled")
designer.update(1)
assert(lib[libIndex("Glass Jaw")].v[4] == 2, "Over-budget draft was not saved")
-- An edit made elsewhere (the native menu) shows up after the next refresh.
lib[1].name = "Renamed in game"; libRevision = libRevision + 1
designer.update(1)
capturedText = {}
pick(selects, "Renamed in game##design1", true)
click("Test in Lab sandbox")
before = #lib
click("Duplicate")
assert(#lib == before + 1)
click("Delete")
assert(#lib == before)
click("Add starter designs")
-- Export, then import into the same library.
click("Export to file")
assert(saved.version == 1 and #saved.designs == #lib, "Export wrote the library")
before = #lib
click("Import " .. before .. " from file")
assert(#lib == 2 * before, "Import did not add the file's designs")
-- The Build 9 single blueprint can be imported once the file is rescanned.
os.remove("quickhack-designs.json")
local legacy = assert(io.open("prototype-recipe.json", "w"))
legacy:write(json.encode({version = 2, recipe = {name = "Old blueprint", first = {1,1,0,4,25,1}, second = {3,2,1,4,25,1}}}))
legacy:close()
playerAvailable = false
designer.update(1)
playerAvailable = true
designer.update(1)
before = #lib
click("Import 1 from file")
assert(#lib == before + 1 and lib[#lib].name == "Old blueprint", "Legacy blueprint import")
-- Native quickhacks tab: browse, compile a recreation, approximate, get the native.
meter = "[native] OverheatLevel3 on Grunt: 120 damage in 6 hits"
designer.update(1)
capturedText = {}
draw()
local shownSummary, shownMeter = false, false
for _, text in ipairs(capturedText) do
  if text == "Summary of Overheat T1" then shownSummary = true end
  if text == meter then shownMeter = true end
end
assert(shownSummary and shownMeter, "Reference summary or meter not shown")
pick(selects, "Overheat T3##ref2", true)
click("B##reference")
assert(calls.refCompile[1] == 2 and calls.refCompile[2] == 1, "Reference compile by catalog index")
before = #lib
click("Add craftable version to designs")
assert(calls.refApprox == 1 and #lib == before + 1, "Approximation did not reach the library")
pick(checks, "Free mode (testing: no component costs)", false)
click("Get native program (free mode)")
assert(calls.refGive == nil, "Native program given outside free mode")
pick(checks, "Free mode (testing: no component costs)", true)
click("Get native program (free mode)")
assert(calls.refGive == 1)
pick(selects, "Ping T1 (native only)##ref3", true)
click("Re-read with current stats")
assert(calls.refRefresh == 1)
click("Clear meter")
assert(calls.meterClear == 1)
-- The dump writes a few programs per frame and finishes on its own.
click("Dump all to file")
assert(calls.dumped == nil, "Dump ran in the click frame")
designer.update(0.016)
designer.update(0.016)
assert(calls.dumped == #refTitles, "Dump did not cover every program")
local dumpFile = assert(io.open("native-quickhacks-dump.txt", "r"))
local dumped = dumpFile:read("*a"); dumpFile:close()
assert(dumped:find("build 13", 1, true) and dumped:find("=== Ping T1", 1, true), "Dump file content")
click("Dump all to file")
playerAvailable = false
designer.update(0.016)
playerAvailable = true
assert(calls.dumped == #refTitles, "Dump continued without a save")
click("Open in-game designer menu")
hotkeys.SDPDesignerMenu()
assert(calls.openMenu == 2, "Native menu not requested")
-- Version mismatch refuses compiling and does not touch the library.
backendVersion = 2
compiles = #calls.compile
pick(combos, "Condition##Primary rule", 0)
click("C##compile")
assert(#calls.compile == compiles, "Compiled against an outdated backend")
backendVersion = 13
designer.shutdown()

playerAvailable = false
hotkeys.SDPPrototypeUpload()
hotkeys.SDPPrototypeSpread()
workbench.update(1)
designer.update(1)
assert(calls.upload == 2 and calls.spread == 1)
workbench.setOverlay(false)
draw()
print("PASS: designer mirrors the save library: editing, push, compile, slots, chips, export/import")
'''

with tempfile.TemporaryDirectory(prefix="sdp-workbench-", dir=ROOT / ".stage") as temp:
    assert Path(temp).resolve().is_relative_to(ROOT / ".stage")
    previous = os.getcwd()
    try:
        os.chdir(temp)
        lua.execute(test_script)
    finally:
        os.chdir(previous)

# The cost model is written twice (Lua for the designer, redscript for the game).
# Evaluate the redscript formulas and compare them with the Lua ones.
import re
reds = (ROOT / "r6/scripts/SDPQuickhackCrafting/CustomPrograms.reds").read_text(encoding="utf-8")
designs_lua = lua.eval('require("quickhack_designs")')
for name, key in (("Ram", "ram"), ("UploadTenths", "uploadTenths"), ("Cooldown", "cooldown"),
                  ("Uncommon", "uncommon"), ("Rare", "rare")):
    match = re.search(r"func %s\(points: Int32\) -> Int32 \{ return (.+?); \}" % name, reds)
    assert match, name
    expr = match.group(1).replace("/", "//")
    ternary = re.fullmatch(r"(.+?) \? (.+?) : (.+)", expr)
    if ternary:
        expr = "(%s) if (%s) else (%s)" % (ternary.group(2), ternary.group(1), ternary.group(3))
    for points in range(0, 41):
        expected = eval(expr, {}, {"points": points})
        assert designs_lua.derive(points)[key] == expected, (name, points)
print("PASS: Lua and redscript cost formulas agree for 0-40 points")

# New saves are seeded from SDPQHSpec.Starters(); it must match the Lua starters.
library_reds = (ROOT / "r6/scripts/SDPQuickhackCrafting/DesignLibrary.reds").read_text(encoding="utf-8")
body = library_reds[library_reds.index("func Starters()"):]
body = body[:body.index("return list;")]
reds_starters = []
for match in re.finditer(r'SDPQHSpec\.Make\("([^"]+)", ([^)]*)\)', body):
    values = [float(x) for x in match.group(2).split(",")]
    reds_starters.append((match.group(1), values))
lua_starters = designs_lua.starters()
assert len(reds_starters) == len(lua_starters), (len(reds_starters), len(lua_starters))
for i, (name, values) in enumerate(reds_starters, start=1):
    d = lua_starters[i]
    expected = [d.first[k] for k in range(1, 7)] + [d.second[k] for k in range(1, 7)]
    expected += [designs_lua.indexOf(designs_lua.lifetimes, d.lifetime), d.spread]
    assert d.name == name and [float(x) for x in expected] == values, (name, values, expected)
print("PASS: redscript starter designs match the Lua starters")

# Payload costs and texts exist in both languages too.
runtime_reds = (ROOT / "r6/scripts/SDPQuickhackCrafting/PrototypeCrafting.reds").read_text(encoding="utf-8")
light_line = re.search(r"let light: Bool = (.+?);", runtime_reds).group(1)
light = {int(x) for x in re.findall(r"payload == (\d+)", light_line)}
recipes_lua = lua.eval('require("prototype_recipes")')
for payload in range(1, 13):
    expected = 1 + (2 if payload in light else 3)  # on-upload trigger costs 1
    assert recipes_lua.ruleCost(lua.table(4, payload, 0)) == expected, (payload, expected)
assert recipes_lua.ruleCost(lua.table(4, 13, 0)) is None
text_body = reds[reds.index("func PayloadText(p: Int32)"):]
text_body = text_body[:text_body.index("return \"nothing\";")]
reds_texts = {int(k): v for k, v in re.findall(r'case (\d+): return "([^"]+)";', text_body)}
lua_texts = designs_lua.payloadText
for payload in designs_lua.programPayloads.values():
    assert reds_texts[payload] == lua_texts[payload], (payload, reds_texts.get(payload), lua_texts[payload])
assert sorted(reds_texts) == sorted(designs_lua.programPayloads.values())
print("PASS: payload costs and texts agree between Lua and redscript (payloads 1-12)")

# Ensure adding the workbench did not replace the existing CET event owners.
source = (MOD / "init.lua").read_text(encoding="utf-8")
for event in ("onDraw", "onUpdate", "onOverlayOpen", "onOverlayClose"):
    assert source.count(f'registerForEvent("{event}",') == 1, event
for path in MOD.glob("*.lua"):
    lua.execute("assert(loadstring(...))", path.read_text(encoding="utf-8"))
print("PASS: all CET files parse under LuaJIT; event handlers remain single-owner")
