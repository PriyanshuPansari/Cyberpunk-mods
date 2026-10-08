"""Preview or deploy the local split SDP mods; never deploy the legacy monolith."""
import argparse
from datetime import datetime
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME = 'C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077'
PRESERVE = ('settings.json', 'prototype-recipe.json', 'quickhack-designs.json',
            'quickhack-lab-report.txt', '*.log', 'db.sqlite3*', '*.vortex_backup',
            '__folder_managed_by_vortex', '*.pyc')


def payload(path):
    return path.is_file() and not any(fnmatch.fnmatch(path.name.lower(), p) for p in PRESERVE)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def contained(path, parent):
    assert path.resolve().is_relative_to(parent.resolve()), f'Path escapes root: {path}'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--apply', action='store_true', help='Compile, back up, then update staging and game')
    ap.add_argument('--game', default=DEFAULT_GAME)
    ap.add_argument('--stage', default=str(Path(os.environ['APPDATA']) / 'Vortex/cyberpunk2077/mods'))
    args = ap.parse_args()
    game, stage = Path(args.game).resolve(), Path(args.stage).resolve()
    assert (game / 'r6/cache/final.redscripts').is_file(), 'Game bundle missing'
    assert not (game / 'r6/scripts/SkillDrivenProgression/PrototypeCrafting.reds').exists(), 'Disable legacy all-in-one mod and deploy split mods first'
    mods = [(name, ROOT / name) for name in ('SDP-Core', 'SDP-Skills', 'SDP-Perks', 'SDP-QuickhackCrafting', 'SDP-Combat')]
    mods += [(name, ROOT / 'SDP-Patches' / name) for name in ('SDP-Cigarettes', 'SDP-CyberwareEx', 'SDP-ENCTakedowns', 'SDP-ScannerDilation')]
    cq = list(stage.glob('Custom Quickslots*'))
    if len(cq) == 1:
        mods.append((cq[0].name, ROOT / 'SDP-Patches/SDP-Cigarettes/compat/CustomQuickslots'))
    elif len(cq) > 1:
        raise RuntimeError('Multiple Custom Quickslots staging copies; choose the active copy before deploying')
    expected, stale, changes = {}, [], []
    for mod, source in mods:
        staged = stage / mod
        assert staged.is_dir(), f'Mod is not installed in Vortex: {mod}'
        files = {p.relative_to(source).as_posix(): p for base in ('r6', 'bin', 'archive')
                 for p in (source / base).rglob('*') if payload(p)}
        assert files, f'No runtime files: {source}'
        # Owned source folders must already be present in this established installation.
        assert any((game / rel).exists() for rel in files), f'{mod} not deployed; enable it in Vortex first'
        for rel, src in files.items():
            assert rel not in expected, f'Conflicting source ownership: {rel}'
            expected[rel] = (mod, src)
            for label, dest, parent in [('stage', staged / rel, staged), ('game', game / rel, game)]:
                contained(dest, parent)
                if digest(dest) != digest(src):
                    changes.append((label, mod, rel, src, dest, digest(dest)))
        # Only remove obsolete files owned by these SDP staging packages. Never
        # prune the shared game's archive/mod folder or another mod's package.
        if mod.startswith('SDP-'):
            for p in staged.rglob('*'):
                if not payload(p):
                    continue
                rel = p.relative_to(staged).as_posix()
                if rel.split('/')[0] not in ('r6', 'bin', 'archive') or rel in files:
                    continue
                dest = game / rel
                assert not dest.exists() or digest(dest) == digest(p), f'Obsolete path has game-only edits: {dest}'
                stale.append(('stage', mod, rel, p, digest(p)))
                if dest.exists(): stale.append(('game', mod, rel, dest, digest(dest)))
        changed = sum(1 for x in changes if x[0] == 'game' and x[1] == mod)
        print(f'{mod}: {len(files)} runtime files, {changed} game updates')
    print(f'Total: {len(expected)} files; {len(changes)} writes; {len(stale)} obsolete file removals (backed up).')
    if not args.apply:
        print('Preview only. Run with --apply to compile and deploy.')
        return
    running = subprocess.run(['powershell', '-NoProfile', '-Command', '(Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue).Id'], capture_output=True, text=True)
    assert not running.stdout.strip(), 'Close Cyberpunk 2077 before deploying'
    runs = ROOT / '.deployment'
    runs.mkdir(exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=datetime.now().strftime('%Y%m%d-%H%M%S-'), dir=runs))
    shadow = run / 'compile/scripts'
    for src in (game / 'r6/scripts').rglob('*.reds'):
        rel = src.relative_to(game).as_posix()
        if src.relative_to(game / 'r6/scripts').parts[0].lower() == 'combatarena': continue
        if any(x[0] == 'game' and x[2] == rel for x in stale): continue
        dst = shadow / src.relative_to(game / 'r6/scripts')
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    for rel, (_, src) in expected.items():
        if rel.startswith('r6/scripts/') and rel.endswith('.reds'):
            dst = shadow / Path(rel).relative_to('r6/scripts')
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    # Older standalone compiler rejects temporary arrays passed by reference.
    # Normalize only these known third-party expressions in the validation copy;
    # deployed sources remain untouched. Keep a record of this validation limit.
    compatibility = {
        'EquipmentEx/EquipmentEx.reds': [
            ('this.m_filtersRadioGroup.SetData(this.m_filterManager.GetIntFiltersList());',
             'let sdpCompatFilterList = this.m_filterManager.GetIntFiltersList();\n        this.m_filtersRadioGroup.SetData(sdpCompatFilterList);')],
        'RedscriptConfigFramework/DVRCF_HubPopup.reds': [
            ('let spaces: Int32 = ArraySize(StrSplit(label, " ")) - 1;',
             'let sdpCompatLabelParts = StrSplit(label, " ");\n    let spaces: Int32 = ArraySize(sdpCompatLabelParts) - 1;'),
            ('let count: Int32 = ArraySize(RedLogger.LogFilesIn(lp.source, this.m_schema.tabs[0].sections[this.m_activeSection].name));',
             'let sdpCompatLogFiles = RedLogger.LogFilesIn(lp.source, this.m_schema.tabs[0].sections[this.m_activeSection].name);\n            let count: Int32 = ArraySize(sdpCompatLogFiles);')],
    }
    adapted = []
    for rel, replacements in compatibility.items():
        path = shadow / rel
        if not path.exists(): continue
        text = path.read_text(encoding='utf-8')
        for before, after in replacements:
            if before in text:
                assert text.count(before) == 1, f'Ambiguous compiler workaround: {rel}'
                text = text.replace(before, after)
                adapted.append({'file': rel, 'expression': before})
        path.write_text(text, encoding='utf-8')
    (run / 'compile-compatibility.json').write_text(json.dumps({'excluded': ['CombatArena'], 'temporary_copy_only': adapted}, indent=2))
    output = run / 'compile/verified.redscripts'
    result = subprocess.run([str(ROOT / 'redscript-cli.exe'), 'compile', '-s', str(shadow),
                             '-s', str(game / 'red4ext/plugins'), '-b', str(game / 'r6/cache/final.redscripts'),
                             '-o', str(output)], capture_output=True, text=True)
    log = result.stdout + result.stderr
    (run / 'compile.log').write_text(log, encoding='utf-8')
    if result.returncode or not output.exists() or 'Output successfully saved' not in log:
        print(log[-9000:])
        raise RuntimeError(f'Compilation failed; no deployed files changed. See {run / "compile.log"}')
    print(f'Compile passed (CombatArena excluded; {len(adapted)} third-party expressions adapted only in validation copies).')
    # Reject concurrent destination changes before the first mutation.
    for _, _, _, _, dest, old in changes: assert digest(dest) == old, f'Destination changed: {dest}'
    for _, _, _, dest, old in stale: assert digest(dest) == old, f'Destination changed: {dest}'
    journal = []
    for label, mod, rel, src, dest, old in changes:
        saved = run / 'backup' / label / mod / rel
        if dest.exists():
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dest, saved)
        dest.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix='.sdp-deploy-', dir=dest.parent)
        os.close(fd)
        try:
            shutil.copy2(src, temporary)
            os.replace(temporary, dest)  # break Vortex hardlinks before writing
        finally:
            if Path(temporary).exists(): Path(temporary).unlink()
        journal.append({'action': 'write', 'destination': str(dest), 'backup': str(saved) if old else None, 'sha256': digest(src)})
        (run / 'changes.json').write_text(json.dumps(journal, indent=2))
    for label, mod, rel, dest, old in stale:
        contained(dest, stage / mod if label == 'stage' else game)
        saved = run / 'backup' / label / mod / rel
        saved.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dest, saved)
        dest.unlink()  # individual verified owned file, never a recursive deletion
        journal.append({'action': 'remove', 'destination': str(dest), 'backup': str(saved), 'sha256': old})
        (run / 'changes.json').write_text(json.dumps(journal, indent=2))
    manifest = []
    for rel, (mod, src) in expected.items():
        sha = digest(src)
        assert digest(stage / mod / rel) == sha and digest(game / rel) == sha, f'Verification failed: {rel}'
        manifest.append({'mod': mod, 'file': rel, 'sha256': sha})
    (run / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    print(f'PASS: {len(manifest)} files verified in source, Vortex staging and game.')
    print(f'Backup, manifest and compile log: {run}')
    print('Restart the game; full runtime compilation/gameplay is verified only at launch.')


if __name__ == '__main__':
    main()
