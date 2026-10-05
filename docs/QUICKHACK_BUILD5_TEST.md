# Independent quickhack primitives — Build 5

Fully restart Cyberpunk, open the workbench and confirm **Build 5**. Enable/reset
the session. These presets do not require equipping or learning a native quickhack;
the existing scanner selection and upload binding are used to choose a target.

| Primitive | Implementation |
|---|---|
| Blindness | Private status with the engine's Blind sensory tag |
| Thermal, electrical, chemical, physical damage | Our scheduler creates attributed, single-target attacks through the game's damage pipeline |
| Movement restriction | Private status package multiplies MaxSpeed by 0.2; NPC locomotion response needs testing |
| Stun | Private Stunned status; NPC reaction needs testing |
| Duration | Per rule: 2, 4 or 8 simulation seconds |
| Pulse amount / interval | 10, 25 or 50 base damage; every 0.5, 1 or 2 seconds |
| Trigger / condition | Upload, reload, ranged hit, headshot, delayed activation; always, already blind, already heated |
| Propagation | Existing manual program propagation also copies active custom effects, retaining expiry and next pulse time |

Damage is a base amount, not a promise of final HP loss. Defenses and other combat
mods can change the result. Pulses begin on the next workbench update (normally
within 0.1 seconds). The same payload refreshes on a target; it never stacks with
itself. Different payloads coexist. Missed ticks are skipped instead of causing
a damage burst after a stalled update. Disable/reset clears owned custom effects.
Native reference effects remain a separate comparison feature.

## First test

1. Choose **Optics core**, select an ordinary enemy in the scanner and press upload.
   Look for `blind=active` and `primitive 1: registered` in the selected-target
   status. Observe the enemy's sight/aim behavior and recovery after four seconds.
2. Choose **Thermal core** on a fresh target. Observe HP loss in separate pulses
   over four seconds. `Pulses queued` should rise about four times with default
   timing; it counts requests, not confirmed damage. A rising count without HP
   loss is an attack-pipeline failure to report, not a successful test.
3. Set duration to eight seconds, damage to ten and interval to two seconds.
   Upload on a fresh target and compare the pacing and total HP loss.
4. While that effect is active, select its original target and use **Propagate
   installed program**. Up to three nearby eligible enemies should receive the
   remaining effect. Copies must stop alongside the source, not eight seconds
   after propagation. Copies cannot propagate again.
5. Test **Cripple core** for visible movement restriction and normal movement
   after expiry. Then test **Caustic blackout** (blindness plus chemical pulses)
   and **Headshot furnace** (movement restriction, then thermal pulses on headshot).
6. Disable/reset during an effect: damage requests must stop and owned statuses
   must clear. Save/load a tuned recipe and confirm its parameters persist.

Rearm an installed program to repeat its upload trigger. Changing the recipe in
the editor does not change an installed program; wait for its 30-second lifetime
to end or reset the session before uploading the changed recipe to that target.

Compilation and LuaJIT bridge/validation tests pass. Gameplay tests above remain
pending. These reconstruct core behaviors, not full native tier bonuses, AI
animations, visuals, RAM costs, trace, upload queues or a balanced crafting economy.
The 12-point budget currently prices trigger/payload/condition only; strength and
timing controls are intentionally unbalanced exploration controls.
