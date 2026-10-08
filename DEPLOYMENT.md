# Deploying the SDP mods

## Pull and deploy in one command

Close Cyberpunk, then double-click **Pull-And-Deploy.cmd** in this workspace.
Or run from PowerShell:

```powershell
Set-Location 'C:\Users\incre\Documents\New project'
python tools/Pull-And-Deploy.py
```

This pulls the currently configured upstream branch
`claude/zealous-mccarthy-m32m6r` in
`C:\Users\incre\Documents\Cyberpunk-mods-upstream-sync`, using a fast-forward-only
pull. It then merges upstream file changes into this workspace and runs the
validated deployment procedure below. The nested local repositories are preserved.

Local edits are retained through a three-way merge; conflicts stop the operation
before any workspace or game files are changed. Conflict details and source
backups are saved under `.deployment/pull-*/`. The last synchronized commit lives
in `.deployment/pull-state.json`; keep that file for future runs. The initial
baseline is the verified previous import `8d337cf`.

Compilation failure prevents game/staging deployment but leaves pulled source
updates available for repair. Rerun the same command afterward. No reset, stash,
forced pull, push, or automatic branch switching is performed. To change the
upstream location/branch, review `UPSTREAM` and `BRANCH` in the script explicitly.

The synchronization regression check is `python tools/Test-Pull-And-Deploy.py`.
It uses temporary local repositories and a fake deploy command, never game files.

Latest pull/deployment: Build 14, upstream commit `dd31957`, from
`claude/zealous-mccarthy-m32m6r`. Eleven game files and their staging copies were
updated, with all 117 runtime files hash-verified. Standalone compilation and the
Quickhack Crafting LuaJIT/designer/native-dump checks passed; gameplay still needs
a fresh game launch. Deployment backup: `.deployment/20261008-024706-6w2y_vs6/`.

Local compiler fixes retain `Equals(entry.program, program)` in
`ComparisonMeter.reds`, replace `native` identifiers with descriptive names in
`CustomProgramRecords.reds`, `CustomPrograms.reds`, `NativeReferences.reds` and
`QuickhackPrimitives.reds`, and use `Equals(this.parts[i].after, after)` for the
Boolean comparison in `NativeReferences.reds`. These fixes are local and deployed;
future pulls retain them through the same three-way merge handling.

The source folders in this workspace are the editable copies. Vortex keeps its
own staging copies, and Cyberpunk loads the files in the game folder. An update
must reach **both Vortex staging and the game**.

## Update this existing installation

Close Cyberpunk 2077. Open PowerShell and run:

```powershell
Set-Location 'C:\Users\incre\Documents\New project'

# Preview the files that need updating; changes nothing.
python tools/Deploy-Mods.py

# Validate, back up, deploy and verify.
python tools/Deploy-Mods.py --apply
```

The helper updates all nine installed split SDP mods and the Cigarettes patch
for Custom Quickslots, when exactly one Custom Quickslots staging copy exists.
It checks that these packages are already installed/deployed. It does not enable
mods, switch Vortex profiles, or install dependencies.

It performs these steps:

1. Collect runtime files from each mod's `r6`, `bin` and `archive` folders.
2. Compile a temporary copy of the intended script installation against the
   real game bundle and installed plugin scripts. Stop before deployment on error.
3. Back up changed staging/game files, then replace them individually. Replacement
   breaks Vortex hardlinks so changing staging cannot silently overwrite the game.
4. Back up and remove obsolete runtime files found in the owned SDP staging
   packages. It never mirrors or clears shared game directories.
5. Verify SHA-256 hashes across source, staging and game for every runtime file.

Success ends with `PASS: ... files verified in source, Vortex staging and game`.
The helper already writes the game copies, so another Vortex Deploy is not needed
for this update. Vortex's staging copies also contain the new version for future
deployments. The helper does not modify Vortex's profile/deployment database.

Launch the game afterward. Existing running sessions cannot load new redscript
classes or TweakXL records by reloading CET alone.

### Paths and prerequisites

| Purpose | Default path |
|---|---|
| Workspace | `C:\Users\incre\Documents\New project` |
| Vortex staging | `%APPDATA%\Vortex\cyberpunk2077\mods` |
| Game | `C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077` |
| Local compiler | Workspace `redscript-cli.exe` |
| Backups and validation logs | Workspace `.deployment\<run-id>\` |

Python, PowerShell, the local compiler, and the installed game's
`r6\cache\final.redscripts` are required. For different locations:

```powershell
python tools/Deploy-Mods.py --game 'D:\Games\Cyberpunk 2077' --stage 'D:\Vortex Mods\cyberpunk2077' --apply
```

The current compiler has known limitations: CombatArena is excluded from the
temporary check, and three expressions in Equipment-EX/Redscript Config Framework
are rewritten only in temporary validation copies. Their installed files remain
unchanged. Each run records these exceptions in `compile-compatibility.json`.
This is not a complete in-game compatibility or gameplay test.

## First installation or normal Vortex deployment

For a new setup, install the chosen split folders as separate Vortex mods, with
their `r6`, `bin` and `archive` directories at each mod package's root. Install
the dependencies listed in each README. Then enable the packages and Deploy Mods
in Vortex. The helper above is intended for subsequent updates to this established
installation.

To update staging through the existing PowerShell helpers instead:

```powershell
Set-Location 'C:\Users\incre\Documents\New project'
& .\SDP-Core\tools\Sync-ToVortex.ps1
& .\SDP-Skills\tools\Sync-ToVortex.ps1
& .\SDP-Perks\tools\Sync-ToVortex.ps1
& .\SDP-QuickhackCrafting\tools\Sync-ToVortex.ps1
& .\SDP-Combat\tools\Sync-ToVortex.ps1
& .\SDP-Patches\tools\Sync-ToVortex.ps1
```

**These PowerShell scripts only copy to staging.** Afterward click **Deploy Mods**
in Vortex, then launch the game. They do not perform the Python helper's
compilation, backup, obsolete-file cleanup or hash verification.

For selected optional patches, use, for example:

```powershell
& .\SDP-Patches\tools\Sync-ToVortex.ps1 -Only SDP-Cigarettes,SDP-ScannerDilation
```

## Package ownership

| Source folder | Vortex package | Main script folder in game |
|---|---|---|
| `SDP-Core` | `SDP-Core` | `SDPCore` |
| `SDP-Skills` | `SDP-Skills` | `SDPSkills` |
| `SDP-Perks` | `SDP-Perks` | `SkillDrivenProgression` |
| `SDP-QuickhackCrafting` | `SDP-QuickhackCrafting` | `SDPQuickhackCrafting` |
| `SDP-Combat` | `SDP-Combat` | `SDPCombat` |
| `SDP-Patches/SDP-Cigarettes` | `SDP-Cigarettes` | `SDPCigarettes` |
| `SDP-Patches/SDP-CyberwareEx` | `SDP-CyberwareEx` | `SDPCyberwareEx` |
| `SDP-Patches/SDP-ENCTakedowns` | `SDP-ENCTakedowns` | `SDPENCTakedowns` |
| `SDP-Patches/SDP-ScannerDilation` | `SDP-ScannerDilation` | `SDPScannerDilation` |

Keep the old all-in-one **SkillDrivenProgression Vortex package disabled**.
The remaining `SkillDrivenProgression` script/CET folders belong to SDP-Perks;
do not delete them as supposed leftovers. Never run the legacy repository's sync
script while using the split packages.

## Preserved files and recovery

The deployment helper preserves settings, `prototype-recipe.json`,
`quickhack-designs.json`, lab reports, logs, CET databases and Vortex backup files.
It does not touch saved games. Source documentation, development tools,
`archive-source` and `archive-disabled` are not runtime payloads.

Every applied update creates:

- `compile.log` and `compile-compatibility.json`: validation results and limitations.
- `changes.json`: exact changed paths and their backup locations. A null backup
  means the file was newly added.
- `backup/stage/...` and `backup/game/...`: previous versions of changed files.
- `manifest.json`: deployed file paths and SHA-256 hashes after a successful run.

To roll back, close the game and restore the listed backups to their exact
`destination` paths in both staging and game. Remove newly added files only when
`changes.json` identifies them as additions. Do not copy the validation bundle
into the game's cache or recursively delete shared mod folders.

## Check after launching

Open `r6\logs\redscript_rCURRENT.log` under the game folder and look for
`Compilation complete` / `Output successfully saved`. On failure, use the first
actual error and named file; a standalone validation pass cannot replace this.

For the current Quickhack Designer update, check the **Crafting > Quickhack
Designer** tab (Codeware required) or the CET designer window. Check the designer
and program chips before relying on them during a longer session. The new Lua
designer/lab tests passed during deployment; in-game UI and gameplay still need
a launch check.

## Deployment completed on 2026-10-07

Updated 21 game files and their matching staging copies: 14 Quickhack Crafting,
6 Combat and 1 Skills file. Verified all 113 runtime files across the nine SDP
packages and the Custom Quickslots compatibility patch. No obsolete files were
removed. The run is `.deployment/20261007-204934-9akjwety/`.
