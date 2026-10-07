# SDP Quickhack Crafting

Part of SkillDrivenProgression (see SDP-Core). A **Quickhack Designer** for building two-rule quickhacks from the
mod's primitives, as a native **Crafting > Quickhack Designer** tab (needs Codeware) and a CET window. Designs are
stored in your save and compile into program chips that you install in your cyberdeck and use from the game's
scanner quickhack wheel, with their own RAM cost, upload time and cooldown. **Native quickhacks** rebuilds every native
quickhack, at every tier, from the same primitives with the native numbers, wearing each native status's full look
(animation, effects, AI reaction and mechanics); a comparison meter measures the native program against its
recreation. The CET window's Lab tab keeps the free sandbox, weapon bindings and native quickhack comparison tools.
Standalone: needs redscript, TweakXL and CET, not SDP-Core; Codeware is optional and adds the native menu.

> **Do not deploy the new parts alongside the old all-in-one `SkillDrivenProgression` Vortex mod.** Both define the
> same functions, so redscript would fail to compile. Disable the old mod first (see SDP-Core's README, "Switching over").

- [Quickhack Designer](docs/QUICKHACK_DESIGNER.md): designing, compiling and installing program chips; cost model; checks.
- [Recreating native quickhacks](design/NATIVE_RECREATION.md): what the native dump shows, how Build 14 recreates each
  hack, native bugs it avoids, and what is still missing. The dump itself is in [design/native-dump](design/native-dump/README.md).
- [Component crafting prototype](docs/PROTOTYPE_CRAFTING.md): the Lab sandbox, setup and gameplay checks.
- [Quickhack primitives and lab](design/QUICKHACK_PRIMITIVES.md): native spreading, component inspection, reconstruction.
- [Build 5 test](docs/QUICKHACK_BUILD5_TEST.md), [optics runtime trace](docs/OPTICS_RUNTIME_TRACE.md).
- [Blindness, weapon interruption and accuracy](design/BLINDNESS_WEAPON_ACCURACY.md): source findings, measured multipliers, and the SDP-Combat interaction.

The CET window lives in `bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting/`: `designer.lua` (window),
`quickhack_designs.lua` (design and cost model), `prototype.lua` (Lab tab) and `prototype_recipes.lua` (rule catalog).
The native menu is `DesignerUI.reds`, the save's design library `DesignLibrary.reds`, the native references
`NativeReferences.reds` with `ComparisonMeter.reds`, and the program chips
`r6/tweaks/SDPQuickhackCrafting/CustomPrograms.yaml` with `CustomPrograms.reds` and `CustomProgramRecords.reds`. `tools/TestPrototypeCrafting.py` runs the Lua under LuaJIT.
`tools/ExplainNativeQuickhack.py` reads the compressed native dump (what a hack does, what its recreation rebuilds),
`tools/CompressNativeDump.py` compresses a new dump and `tools/MakeLooseFlats.py` regenerates `LooseFlats.reds`.
