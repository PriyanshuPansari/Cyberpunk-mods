# Vehicle Self-Destruct crash: encounter counter race

Crash: 8 October 2026, 02:51:17 IST, process 58020, faulting thread 42828.
Report folder: `%LOCALAPPDATA%/REDEngine/ReportQueue/Cyberpunk2077-20261008-025117-58020-42828`.
User action: Self-Destruct quickhack on a car. Loading had finished; the crash
screenshot shows the rendered world. The report records 195 seconds of uptime.

## Evidence

The exception is a read access violation at `Cyberpunk2077.exe+0x14ba9e`:
`call qword ptr [r10+0x18]`, with `r10=0x7ff700000000`, accessing
`0x7ff700000018`. The native crash text itself does not identify the mod.

Reading the minidump's script frames finds two simultaneous death callbacks:

| Evidence | Thread 42828 | Thread 34176 |
|---|---|---|
| `SDP_EncounterReset` frame | `0x5ed28fc290` | `0x5ed39fc2f0` |
| Reset bytecode offset | `+0x13f` | `+0x13f` |
| Player development data context | `0x1f01369bf40` | `0x1f01369bf40` |
| Counter array being modified | `0x1f416813790` | `0x1f416813790` |
| Reset loop local counter | 5 | 12 |
| Dying NPC context | `0x1f434c2a9d0` | `0x1f4559829f0` |

Both linked script frame chains lead through `HandleDeathTask`, `HandleDeath`,
`FindAndRewardKiller`, `RewardKiller`, the encounter reward wrapper,
`SDP_EncounterOnNeutralized`, and `SDP_EncounterReset`. Frame code pointers were
checked against the corresponding compiled function's bytecode range. This is
script-frame inspection using SDK layouts, not a symbolized native stack unwind.

The shared Int32 array has capacity **9** but size **11**. Its invalid allocator
call and the two reset loops accessing the same array demonstrate concurrent
mutation. The NPC reward callbacks both saw the encounter as closed and entered
the reset before either could set `m_sdpEncOpen`. A Boolean early-open flag alone
would not provide synchronization.

The failing path belongs to SDP-Perks' encounter log. These frames do not identify
a Quickhack Designer payload or a vehicle-specific effect implementation as the
fault. Multiple deaths from the explosion exposed the encounter race.

## Repair and validation

`EncounterXP.reds` now queues NPC neutralization, combat tick, and player-death
notifications on `PlayerDevelopmentSystem`. The system's request handlers perform
encounter reset/open/close and neutralization updates. Existing NPC deduplication,
reward calls and counter calculations remain in place. The request retains the
victim while its metadata is read. Tick callers retain their existing public API,
including the CET overlay and player loop.

Standalone compilation passed with the deployment helper's existing exclusions
(CombatArena excluded; three third-party expressions adapted in temporary copies).
One source file was deployed to both Vortex staging and the game; all **117**
runtime file hashes match. Backup and compile log:
`.deployment/20261008-114427-t31e62n4/` in the parent workspace.

The patch is local and deployed; it has not been pushed to GitHub. In-game
confirmation remains: reload the save, use vehicle Self-Destruct to neutralize
multiple nearby NPCs, and verify the game stays running and the encounter log
counts each NPC once. Also check that combat end and player death still close the
encounter. This repair addresses the observed reset race, not a blanket claim that
every progression hook is thread-safe.

Local diagnostic reader and its output are under
`.deployment/crash-20261008-025117/` in the parent workspace. It reads the saved
dump without attaching to or modifying a running game.

SDK layout references used for offline decoding:
[script frames](https://github.com/WopsS/RED4ext.SDK/blob/master/include/RED4ext/Scripting/Stack.hpp),
[function records](https://github.com/WopsS/RED4ext.SDK/blob/master/include/RED4ext/Scripting/Functions.hpp),
[compiled code](https://github.com/WopsS/RED4ext.SDK/blob/master/include/RED4ext/Scripting/Script.hpp),
and [dynamic arrays](https://github.com/WopsS/RED4ext.SDK/blob/master/include/RED4ext/Containers/DynArray.hpp).
