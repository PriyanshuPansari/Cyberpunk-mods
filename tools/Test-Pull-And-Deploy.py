"""Exercise synchronization in disposable Git repositories; never touch game files."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('pull_deploy', Path(__file__).with_name('Pull-And-Deploy.py'))
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
run_real = subprocess.run


def git(path, *args):
    return subprocess.check_output(['git', '-C', str(path), *args], stderr=subprocess.STDOUT)


def mock_process_check(args, **kwargs):
    if args[0] == 'powershell':
        return subprocess.CompletedProcess(args, 0, stdout='', stderr='')
    return run_real(args, **kwargs)


with tempfile.TemporaryDirectory(prefix='sdp-pull-test-') as temporary:
    base = Path(temporary)
    remote, checkout, work = base/'remote', base/'checkout', base/'workspace'
    remote.mkdir(); work.mkdir()
    git(remote, 'init', '-b', 'main')
    git(remote, 'config', 'user.name', 'Deployment Test')
    git(remote, 'config', 'user.email', 'deployment-test@example.invalid')
    original = ''.join(f'line {i}\n' for i in range(30))
    (remote/'sample.txt').write_text(original)
    (remote/'removed.txt').write_text('old file\n')
    git(remote, 'add', '.'); git(remote, 'commit', '-m', 'baseline')
    initial = git(remote, 'rev-parse', 'HEAD').decode().strip()
    subprocess.check_call(['git', 'clone', str(remote), str(checkout)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    (work/'sample.txt').write_text(original.replace('line 1\n', 'local edit\n'))
    (work/'removed.txt').write_text('old file\n')
    (work/'tools').mkdir()
    (work/'tools/Deploy-Mods.py').write_text('from pathlib import Path\np=Path("deploy-count");p.write_text(str(int(p.read_text())+1) if p.exists() else "1")\n')
    helper.ROOT, helper.UPSTREAM, helper.BRANCH = work, checkout, 'main'
    helper.STATE, helper.INITIAL = work/'.deployment/pull-state.json', initial
    (remote/'sample.txt').write_text(original.replace('line 25\n', 'upstream edit\n'))
    (remote/'removed.txt').unlink()
    git(remote, 'add', '-A'); git(remote, 'commit', '-m', 'update and delete')
    with patch.object(subprocess, 'run', side_effect=mock_process_check):
        helper.main()
        merged = (work/'sample.txt').read_text()
        assert 'local edit' in merged and 'upstream edit' in merged
        assert not (work/'removed.txt').exists()
        assert (work/'deploy-count').read_text() == '1'
        assert any((work/'.deployment').glob('pull-*/backup/removed.txt'))
        helper.main()
        assert (work/'sample.txt').read_text() == merged
        assert (work/'deploy-count').read_text() == '2'
        state = helper.STATE.read_bytes()
        (remote/'sample.txt').write_text(original.replace('line 25\n', 'upstream edit\n').replace('line 1\n', 'conflicting upstream edit\n'))
        git(remote, 'add', '.'); git(remote, 'commit', '-m', 'conflict')
        try:
            helper.main()
        except RuntimeError as error:
            assert 'overlapping changes' in str(error)
        else:
            raise AssertionError('Conflict did not stop deployment')
        assert (work/'sample.txt').read_text() == merged
        assert helper.STATE.read_bytes() == state
        assert (work/'deploy-count').read_text() == '2'
print('PASS: local edits retained, upstream deletion backed up, repeat run stable, conflict blocks all writes/deployment.')
