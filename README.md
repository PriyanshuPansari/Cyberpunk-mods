# SDP Quickhack Crafting

Part of SkillDrivenProgression (see SDP-Core). Opt-in component workbench: two-rule quickhack programs, spreading,
weapon bindings, and the quickhack primitives lab. Standalone: needs redscript, TweakXL and CET, not SDP-Core.

> **Do not deploy the new parts alongside the old all-in-one `SkillDrivenProgression` Vortex mod.** Both define the
> same functions, so redscript would fail to compile. Disable the old mod first (see SDP-Core's README, "Switching over").

- [Component crafting prototype](docs/PROTOTYPE_CRAFTING.md): setup and gameplay checks.
- [Quickhack primitives and lab](design/QUICKHACK_PRIMITIVES.md): native spreading, component inspection, reconstruction.
- [Build 5 test](docs/QUICKHACK_BUILD5_TEST.md), [optics runtime trace](docs/OPTICS_RUNTIME_TRACE.md).
- [Blindness, weapon interruption and accuracy](design/BLINDNESS_WEAPON_ACCURACY.md): source findings, measured multipliers, and the SDP-Combat interaction.

The CET window lives in `bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting/` (`prototype.lua`, recipes in
`prototype_recipes.lua`). `tools/TestPrototypeCrafting.py` runs the Lua catalog under LuaJIT.
