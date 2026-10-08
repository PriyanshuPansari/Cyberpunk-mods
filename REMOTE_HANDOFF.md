# Continue on another device

Handoff date: **2026-10-09**. Latest user instruction: stop local build completion,
publish the work in progress, and continue remotely. **Do not interpret this
snapshot as a working or deployed TestLab release.**

## Active objective and independent tracks

Build controlled combat arenas for the existing base-game SDP overhaul, then use
them to prioritize armor, injuries, AI, cyberware, netrunning and recon work.
The engram and zombie game modes are **independent tracks**, documented under
[`docs/modes`](docs/modes/README.md). Their implementation must not expand or delay
the current test-arena task.

## Current source and design

Start with [SDP-TestLab](SDP-TestLab/README.md), the
[overhaul vision](docs/OVERHAUL_VISION.md), the
[research index](docs/research/README.md), and the
[validation backlog](docs/research/VALIDATION_BACKLOG.md).

The new TestLab files are a first draft. A separate controller uses Combat Arena's
fixed location catalog and read-only activity checks, with its own entity tag and
queue. Its intended state sequence is idle -> site inspection -> preparing -> ready
-> running -> finished/failed. It does not run the arena shop/wave director.

Eleven candidate presets cover armor, one/two/four shooters, cover/lost-target,
grenadier support, mantis chrome, one/two/four runners and a mixed group. Native
record existence, actual gear, navigation, squad assignment and abilities still
require runtime qualification. The location catalog checks the inspected source
coordinates instead of silently accepting a changed ArenaData version.

## Exactly what has and has not been validated

- The **original installed scripts**, including Combat Arena, compiled successfully
  in a temporary validation copy before the final TestLab controller draft existed.
  The older standalone compiler required temporary expression rewrites in Combat
  Arena, Equipment-EX and Redscript Config Framework. No installed dependency was
  edited. The build tool records these workarounds.
- That baseline result **does not validate Controller.reds, the complete TestLab
  installation, or its CET UI**. No final TestLab compilation was run.
- No game launch, arena gameplay qualification, new-mod deployment or release ZIP
  validation was completed for this build.
- The prior planning-document checks passed before implementation. New code is
  deliberately being handed off unfinished.

## First repair and review tasks

1. Fix the malformed JSON `baseline` concatenation in
   `SDP-TestLab/r6/scripts/SDPTestLab/Controller.reds` (`Publish`, approximately line
   189). The draft line leaves its string literal unfinished. Then run the full
   standalone build and resolve actual compiler diagnostics; do not assume all
   guessed native method signatures compile.
2. Check the controller's calls against the catalog signatures and installed
   redscript/Codeware APIs. In particular, verify time conversion, player combat
   state, item/record formatting, dynamic entity lifecycle and stat-pool units.
3. Review preparation invariants: newly spawned NPCs can potentially act before
   the polling controller neutralizes their attitude. Attachment alone does not
   prove navigation, equipment, floor support or safe AI startup. Fail/clean up an
   invalid preparation instead of counting it as a benchmark.
4. Make first-run placement and return robust against unstreamed geometry and
   session changes. Current site inspection is manual; it is not a runtime floor
   probe. No artificial immortality has been implemented.
5. Review report correctness. It currently samples HP/armor/identity at intervals;
   this is **not** per-hit damage attribution or comprehensive hack telemetry.
   Add stable run identifiers, source/build manifest linkage, clear baseline/end
   timestamps and explicit configuration-drift reporting before balance comparisons.
   Reading SDP armor state must not initialize, repair or mutate it.
6. Check all terminal transitions, callback generations, stale session references,
   tag cleanup, refused-command reports and Combat Arena mutual exclusion. The
   recent encounter-XP crash was concurrent array mutation; keep writes serialized.
7. Verify the CET command map, overlay-close start behavior, disconnect/reload
   cleanup and JSONL export. The proposed Lua lifecycle test file was not finished.
   Implement/run a mocked bridge test plus in-game verification.
8. Finish the scenario provenance file referenced by Scenarios.reds
   (`design/scenario-source-audit.json`); it was not written before interruption.
   Confirm records on the destination installation and retain dependency credits.
9. Run packaging checks and the complete compile. Only then produce an installable
   ZIP and use Vortex for the first installation. The existing root deployment
   helper does not yet manage SDP-TestLab; do not create an unregistered Vortex
   staging folder and call that an installation.

## First in-game acceptance session

Use a separate test save. Qualify one target and one lane, then two/four shooters.
Verify prepare/start/abort/return, ordinary player death, reload, five-minute capture
timeout, and repeated resets without leftover actors. Confirm there is no arena HP
scaling, periodic artificial player-location stimulus, inventory removal or healing.
Record game/difficulty/mod/configuration, player level/loadout and actual NPC gear.
Return/respawn is not a full gameplay-state reset; reload the baseline for comparisons.

After lifecycle qualification, prioritize:

1. D01: scanning/preview must not mutate armor integrity or consume penetration RNG.
2. D02: injuries must use damage after protection, not the earlier native stage.
3. A03/A01: shooter pressure/attribution and enemy knowledge after losing sight.
4. N01: prove one functional runner, then measure native serialization with two/four.
5. A05/C01: grenade supply/throw behavior and actual cyberware activation.
6. Existing-site camera/access/recon tests, using observed security relationships.

These gameplay fixes are next steps, not changes already made by TestLab.

## Setup and portability

The repository includes SDP source, authored archives/resources, documentation,
research helpers and build/deployment scripts. Install Python 3 and obtain the
redscript standalone compiler from its [author repository](https://github.com/jac3km4/redscript).
Use the compiler compatible with the target installation; the prior workspace
README names the existing stack but does not certify a different device's plugins.
Pass `--game` and `--compiler` to TestLab's build script rather than relying on this
machine's default paths. The baseline game executable was 2.31 and local Codeware
was 1.20.5; verify the new setup instead of assuming that inventory transfers.

Game-owned decompiled sources, installed third-party mod packages, compiler/tool
binaries, saves, logs, full validation copies, caches and deployment backups are
not part of this source handoff. Obtain dependencies from their authors and generate
local game references from your own installation. Research manifests/source links
describe the original audit and some contain this machine's absolute paths; they
are historical evidence, not portable runtime inputs. `BuildEvidenceIndex.py`
requires those local reference files when regenerating its output.

Root `Pull-And-Deploy.py` still describes the original local synchronization
checkout/branch. Review its configured path/branch before using it on a new device.
The standard `Deploy-Mods.py` expects the existing SDP packages to already be
installed and accepts explicit game/staging paths. Neither helper should pull an
older branch over this work in progress.

## Other local work included in this source snapshot

The local source tree also contains earlier compiler compatibility fixes and the
serialized encounter-XP request fix documented in
[`CRASH_2026-10-08_ENCOUNTER_RESET.md`](SDP-Perks/docs/CRASH_2026-10-08_ENCOUNTER_RESET.md).
These predate TestLab and had their own validation/deployment history. Keep that
history distinct from the new controller's unvalidated status. The alternate-mode
story/technical plans are retained as documents only.
