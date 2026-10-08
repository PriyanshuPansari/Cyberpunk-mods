"""Pull the configured upstream, merge changed files into this workspace, deploy."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT.parent / 'Cyberpunk-mods-upstream-sync'
BRANCH = 'claude/zealous-mccarthy-m32m6r'
# Verified previous import; subsequent runs record their own synchronization point.
INITIAL = '8d337cf799bb8be82df3fe3600780aea48868069'
STATE = ROOT / '.deployment/pull-state.json'


def git(*args):
    return subprocess.check_output(['git', '-C', str(UPSTREAM), *args])


def normalized(data):
    return data.replace(b'\r\n', b'\n') if data is not None and b'\0' not in data else data


def blob(commit, path):
    result = subprocess.run(['git', '-C', str(UPSTREAM), 'show', f'{commit}:{path}'], capture_output=True)
    if result.returncode: raise RuntimeError(f'Cannot read upstream blob {commit}:{path}')
    return result.stdout


def main():
    assert (UPSTREAM / '.git').exists(), f'Upstream checkout missing: {UPSTREAM}'
    assert git('branch', '--show-current').decode().strip() == BRANCH, 'Upstream branch changed; review before pulling'
    assert not git('status', '--porcelain').strip(), 'Upstream checkout contains local changes; no pull performed'
    running = subprocess.run(['powershell', '-NoProfile', '-Command', '(Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue).Id'], capture_output=True, text=True)
    assert not running.stdout.strip(), 'Close Cyberpunk 2077 first'
    STATE.parent.mkdir(exist_ok=True)
    baseline = json.loads(STATE.read_text())['commit'] if STATE.exists() else INITIAL
    print(f'Pulling {BRANCH} in {UPSTREAM}', flush=True)
    subprocess.run(['git', '-C', str(UPSTREAM), 'pull', '--ff-only'], check=True)
    incoming = git('rev-parse', 'HEAD').decode().strip()
    subprocess.run(['git', '-C', str(UPSTREAM), 'merge-base', '--is-ancestor', baseline, incoming], check=True)
    run = Path(tempfile.mkdtemp(prefix='pull-', dir=STATE.parent))
    changes = git('diff', '--name-status', '-z', '--no-renames', baseline, incoming).decode().split('\0')
    plan, conflicts = [], []
    for i in range(0, len(changes) - 1, 2):
        status, relative = changes[i:i+2]
        rel = Path(relative)
        target = ROOT / rel
        assert not rel.is_absolute() and '..' not in rel.parts and '.git' not in rel.parts
        assert target.resolve().is_relative_to(ROOT.resolve())
        assert rel.parts[0] != '.deployment', 'Upstream cannot replace deployment state'
        base = None if status == 'A' else blob(baseline, relative)
        new = None if status == 'D' else blob(incoming, relative)
        local = target.read_bytes() if target.exists() else None
        if normalized(local) == normalized(new): continue
        if normalized(local) == normalized(base):
            merged = new
        elif new is None or local is None or base is None or any(b'\0' in x for x in (base, local, new)):
            conflicts.append(relative)
            continue
        else:
            area = run / 'merge' / rel
            area.parent.mkdir(parents=True, exist_ok=True)
            paths = [Path(str(area) + suffix) for suffix in ('.local', '.base', '.upstream')]
            for path, data in zip(paths, (local, base, new)): path.write_bytes(normalized(data))
            result = subprocess.run(['git', 'merge-file', '-p', *map(str, paths)], capture_output=True)
            if result.returncode:
                Path(str(area) + '.conflict').write_bytes(result.stdout)
                conflicts.append(relative)
                continue
            merged = result.stdout
        plan.append((relative, target, local, merged))
    if conflicts:
        raise RuntimeError('Workspace and game unchanged; resolve these overlapping changes before rerunning:\n' + '\n'.join(conflicts) + f'\nMerge details: {run}')
    # Verify all inputs before the first mutation. Back up every changed local file.
    for relative, target, local, merged in plan:
        assert (target.read_bytes() if target.exists() else None) == local, f'Concurrent edit: {relative}'
        if local is not None:
            backup = run / 'backup' / relative
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_bytes(local)
    (run / 'sync-manifest.json').write_text(json.dumps({'before': baseline, 'after': incoming,
        'files': [{'path': p, 'action': 'delete' if merged is None else 'write', 'had_local_file': local is not None}
                  for p, _, local, merged in plan]}, indent=2))
    for relative, target, local, merged in plan:
        if merged is None:
            target.unlink()  # individually validated file; never remove directories
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            fd, temporary = tempfile.mkstemp(prefix='.sdp-pull-', dir=target.parent)
            os.close(fd)
            try:
                Path(temporary).write_bytes(merged)
                os.replace(temporary, target)
            finally:
                if Path(temporary).exists(): Path(temporary).unlink()
    state_temp = STATE.with_suffix('.tmp')
    state_temp.write_text(json.dumps({'commit': incoming, 'branch': BRANCH, 'upstream': str(UPSTREAM)}, indent=2))
    os.replace(state_temp, STATE)
    print(f'Synced {len(plan)} files at {incoming[:7]}. Backup: {run}', flush=True)
    # A failed deploy leaves the synchronized source available to fix and retry.
    subprocess.run([sys.executable, str(ROOT / 'tools/Deploy-Mods.py'), '--apply'], cwd=ROOT, check=True)


if __name__ == '__main__':
    try:
        main()
    except (AssertionError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f'Pull/deploy stopped: {exc}', file=sys.stderr)
        sys.exit(1)
