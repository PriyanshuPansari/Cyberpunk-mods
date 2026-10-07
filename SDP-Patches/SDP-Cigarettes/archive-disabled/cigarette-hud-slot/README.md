# Archived: built-in cigarette HUD slot and Square + D-pad left shortcut

Replaced by Custom Quickslots (see `compat/CustomQuickslots/`). Kept for
reference; nothing in this folder is deployed.

- `r6/scripts/CigaretteSlot.reds` - extra D-pad HUD slot showing cigarettes.
- `r6/scripts/CigaretteInput.reds` - Square-hold + D-pad-left shortcut, pocket
  radio/notification blocking, inventory listener that refreshed the slot.
- `r6/input/SkillDrivenProgression.xml` - Input Loader binding for the Square
  hold action (`SDP_CigaretteSquare`, 0.1 s).

To restore: move the two scripts back to `r6/scripts/SkillDrivenProgression/`,
the XML back to `r6/input/`, move the attach/detach code from
`CigaretteLifecycle.reds` back into `CigaretteInput.reds`, and re-add
`SDP_CigaretteSlotNotify(player, used ? 1 : 2)` in `SDP_UseCigarette`.
