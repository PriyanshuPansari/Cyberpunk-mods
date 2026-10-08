"""Offline packaging checks. Fixtures only; never invokes the game or compiler."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

SPEC = importlib.util.spec_from_file_location('testlab_package', Path(__file__).with_name('Build-Package.py'))
PACKAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE)


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def put(self, relative, text='fixture'):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')
        return path

    def test_payload_preserves_install_roots_excludes_reports_and_settings(self):
        self.put('module/r6/scripts/SDPTestLab/Lab.reds')
        self.put('module/bin/x64/plugins/cyber_engine_tweaks/mods/SDP-TestLab/init.lua')
        self.put('module/bin/x64/plugins/cyber_engine_tweaks/mods/SDP-TestLab/settings.json')
        self.put('module/bin/x64/plugins/cyber_engine_tweaks/mods/SDP-TestLab/reports/run.json')
        self.put('module/r6/scripts/SDPTestLab/session.log')
        self.put('module/tools/secret-development-fixture.txt')
        payload = PACKAGE.collect_payload(self.root / 'module')
        self.assertEqual(set(payload), {'r6/scripts/SDPTestLab/Lab.reds',
            'bin/x64/plugins/cyber_engine_tweaks/mods/SDP-TestLab/init.lua'})
        output = self.root / 'first-install.zip'
        PACKAGE.make_zip(payload, PACKAGE.snapshot(payload), output)
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(set(archive.namelist()), set(payload))

    def test_source_changed_after_validation_cannot_replace_existing_package(self):
        source = self.put('module/r6/scripts/SDPTestLab/Lab.reds', 'reviewed')
        payload = PACKAGE.collect_payload(self.root / 'module')
        hashes = PACKAGE.snapshot(payload)
        output = self.put('release.zip', 'previous-package')
        source.write_text('concurrent-edit', encoding='utf-8')
        with self.assertRaisesRegex(RuntimeError, 'Source changed'):
            PACKAGE.make_zip(payload, hashes, output)
        self.assertEqual(output.read_text(), 'previous-package')
        self.assertEqual(list(self.root.glob('.testlab-package-*')), [])

    def test_zip_is_reproducible_for_identical_payload(self):
        self.put('module/r6/scripts/SDPTestLab/Lab.reds', 'content')
        payload = PACKAGE.collect_payload(self.root / 'module')
        hashes = PACKAGE.snapshot(payload)
        first, second = self.root / 'one.zip', self.root / 'two.zip'
        PACKAGE.make_zip(payload, hashes, first)
        PACKAGE.make_zip(payload, hashes, second)
        self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_compile_overlay_includes_arena_and_only_rewrites_shadow_copies(self):
        bundle = self.put('game/r6/cache/final.redscripts')
        arena = self.put('game/r6/scripts/CombatArena/arena_spawner.reds',
                        'return GetPlayer(GetGameInstance()).GetWorldPosition().X;')
        old = self.put('game/r6/scripts/SDPTestLab/Old.reds', 'obsolete')
        plugin = self.put('game/red4ext/plugins/Codeware/Scripts/Codeware.reds')
        compiler = self.put('compiler.exe')
        self.put('module/r6/scripts/SDPTestLab/Lab.reds', 'new-source')
        source_hashes = {p: PACKAGE.digest(p) for p in [bundle, arena, old, plugin, compiler]}
        run = self.root / 'validation'
        run.mkdir()

        def fake_compile(command, **kwargs):
            output = Path(command[command.index('-o') + 1])
            self.assertTrue(output.is_relative_to(run))
            shadow = run / 'compile/scripts'
            self.assertIn('sdpCompatPlayerPosition', (shadow / 'CombatArena/arena_spawner.reds').read_text())
            self.assertEqual((shadow / 'SDPTestLab/Lab.reds').read_text(), 'new-source')
            self.assertFalse((shadow / 'SDPTestLab/Old.reds').exists())
            output.write_text('compiled-fixture')
            return subprocess.CompletedProcess(command, 0, 'Output successfully saved', '')

        with patch.object(PACKAGE.subprocess, 'run', side_effect=fake_compile):
            result = PACKAGE.compile_overlay(PACKAGE.collect_payload(self.root / 'module'),
                                             self.root / 'game', compiler, run)
        self.assertEqual(result['compatibility']['excluded'], [])
        self.assertEqual({p: PACKAGE.digest(p) for p in source_hashes}, source_hashes)


if __name__ == '__main__':
    unittest.main(verbosity=2)
