import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('portable', ROOT / 'scripts/portable.py')
portable = importlib.util.module_from_spec(spec)
spec.loader.exec_module(portable)


class PortableTests(unittest.TestCase):
    def test_profile_paths(self):
        for location in ('.mozilla/firefox', '.config/mozilla/firefox',
                         '.var/app/org.mozilla.firefox/.mozilla/firefox'):
            with self.subTest(location=location), tempfile.TemporaryDirectory() as tmp:
                home = Path(tmp)
                root = home / location
                profile = root / 'test.default-release'
                profile.mkdir(parents=True)
                (root / 'profiles.ini').write_text(
                    '[Profile0]\nPath=test.default-release\nIsRelative=1\nDefault=1\n')
                self.assertEqual(portable.firefox_profile(home), profile)

    def test_install_default_and_absolute_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            root = home / '.mozilla/firefox'
            root.mkdir(parents=True)
            old, active = root / 'old', home / 'external-profile'
            old.mkdir()
            active.mkdir()
            (root / 'profiles.ini').write_text(
                f'[Profile0]\nPath=old\nDefault=1\n[Profile1]\nPath={active}\nIsRelative=0\n')
            (root / 'installs.ini').write_text(f'[HASH]\nDefault={active}\nLocked=1\n')
            self.assertEqual(portable.firefox_profile(home), active)
            (root / 'installs.ini').unlink()
            (root / 'profiles.ini').write_text(f'[Profile0]\nPath={active}\nIsRelative=0\n')
            self.assertEqual(portable.firefox_profile(home), active)

    def test_no_profile_and_ambiguous_profiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.assertIsNone(portable.firefox_profile(home))
            root = home / '.mozilla/firefox'
            (root / 'one').mkdir(parents=True)
            (root / 'two').mkdir()
            (root / 'profiles.ini').write_text('[Profile0]\nPath=one\n[Profile1]\nPath=two\n')
            self.assertIsNone(portable.firefox_profile(home))

    def test_cinnamon_portability(self):
        text = (ROOT / 'configs/cinnamon/cinnamon.dconf').read_text()
        normalized = portable.transform('cinnamon', text, Path('/home/urodish'))
        self.assertNotIn('/home/urodish', normalized)
        self.assertNotIn('fractional-scale', normalized)
        self.assertNotIn('night-light', normalized)
        self.assertNotIn('text-scaling-factor', normalized)
        self.assertNotIn('Tela-circle-pink-dark', normalized)
        self.assertEqual(portable.transform('cinnamon', normalized, Path('/home/new')), normalized)
        restored = portable.transform('cinnamon', normalized, Path('/home/new'), True)
        self.assertIn('file:///home/new/Pictures/wallpaper-5k.png', restored)
        self.assertNotIn('@HOME@', restored)

    def test_spice_json_and_privacy(self):
        text = json.dumps({'command': {'value': '@HOME@/test'},
                           'recent-apps': {'value': ['private']}, '__md5__': 'old'})
        home = Path('/home/a "quoted" user')
        data = json.loads(portable.transform('spices', text, home, True))
        self.assertEqual(data['command']['value'], str(home / 'test'))
        self.assertNotIn('recent-apps', data)
        self.assertNotIn('__md5__', data)

    def test_launcher_package_alias(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            app = home / '.local/share/applications/code.desktop'
            app.parent.mkdir(parents=True)
            app.write_text('[Desktop Entry]\nName=Code\n')
            text = '[PlankDockItemPreferences]\nLauncher=file:///missing/com.microsoft.VSCode.desktop\n'
            result = portable.transform('launcher', text, home, True)
            self.assertIn(app.as_uri(), result)

    def test_spicetify_does_not_claim_missing_marketplace(self):
        text = (ROOT / 'configs/spicetify/config-xpui.ini').read_text()
        result = portable.transform('spicetify', text, Path('/home/new'), True)
        self.assertNotIn('marketplace', result)
        self.assertNotIn('[Backup]', result)
        self.assertIn('/home/new/.config/spotify/prefs', result)

    @unittest.skipUnless(os.geteuid() != 0 and shutil.which('dconf') and
                         shutil.which('dbus-run-session'), 'requires non-root, dconf and dbus-run-session')
    def test_backup_with_isolated_home(self):
        with tempfile.TemporaryDirectory(prefix='mint-rice-backup-', dir='/tmp/opencode'
                                         if Path('/tmp/opencode').is_dir() else None) as tmp:
            base = Path(tmp)
            repo, home, bin_dir = base / 'repo', base / 'home', base / 'bin'
            home.mkdir()
            bin_dir.mkdir()
            shutil.copytree(ROOT / 'scripts', repo / 'scripts')
            # Inventory commands are deterministic and cannot touch the host.
            for name in ('code', 'flatpak', 'apt-mark', 'dpkg-query', 'fc-list', 'gsettings'):
                command = bin_dir / name
                command.write_text('#!/bin/sh\nexit 0\n')
                command.chmod(0o755)
            profile = home / '.mozilla/firefox/portable.default-release'
            (profile / 'chrome').mkdir(parents=True)
            (profile / 'chrome/userChrome.css').write_text('/* test customization */')
            (profile.parent / 'profiles.ini').write_text(
                '[Profile0]\nPath=portable.default-release\nDefault=1\n')
            spice = home / '.config/cinnamon/spices/CommandRunner@appdevsw/16.json'
            spice.parent.mkdir(parents=True)
            spice.write_text(json.dumps({'form_command': {'value': str(home / 'Templates/vpn-status.sh')}}))
            (home / 'Pictures').mkdir()
            (home / 'Pictures/telegram-wallpaper.png').write_bytes(b'wallpaper-test')
            (home / '.zshrc').write_text(f'export PATH={home}/.opencode/bin:$PATH\n')
            seed = base / 'seed.dconf'
            seed.write_text("[/]\nenabled-applets=['panel1:left:1:CommandRunner@appdevsw:16']\n"
                            f"[desktop/background]\npicture-uri='file://{home}/Pictures/wallpaper-5k.png'\n"
                            "[muffin]\nexperimental-features=['scale-monitor-framebuffer']\n")
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
                       XDG_DATA_HOME=str(home / '.local/share'), XDG_CACHE_HOME=str(home / '.cache'),
                       PATH=str(bin_dir) + ':' + os.environ['PATH'])
            env.pop('DBUS_SESSION_BUS_ADDRESS', None)
            result = subprocess.run(['dbus-run-session', '--', 'bash', '-eu', '-c',
                                     'dconf load /org/cinnamon/ < "$2"; bash "$1/scripts/backup.sh"',
                                     'test', str(repo), str(seed)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            text = (repo / 'configs/cinnamon/cinnamon.dconf').read_text()
            self.assertIn('@HOME@', text)
            self.assertNotIn('experimental-features', text)
            saved = (repo / 'configs/cinnamon/spices/CommandRunner@appdevsw/16.json').read_text()
            self.assertIn('@HOME@/Templates/vpn-status.sh', saved)
            self.assertNotIn(str(home), saved)
            self.assertTrue((repo / 'configs/firefox/chrome/userChrome.css').exists())
            self.assertEqual((repo / 'wallpapers/telegram-wallpaper.png').read_bytes(), b'wallpaper-test')

    @unittest.skipUnless(os.geteuid() != 0 and shutil.which('dconf') and
                         shutil.which('dbus-run-session'), 'requires non-root, dconf and dbus-run-session')
    def test_restore_empty_home_and_repeat(self):
        # A private session bus + XDG directories isolate dconf from the real desktop.
        with tempfile.TemporaryDirectory(prefix='mint-rice-test-', dir='/tmp/opencode'
                                         if Path('/tmp/opencode').is_dir() else None) as tmp:
            home = Path(tmp)
            bin_dir = home / 'bin'
            bin_dir.mkdir()
            code = bin_dir / 'code'
            code.write_text('#!/bin/sh\nexit 0\n')
            code.chmod(0o755)
            env = dict(os.environ, HOME=tmp, XDG_CONFIG_HOME=str(home / '.config'),
                       XDG_DATA_HOME=str(home / '.local/share'), XDG_CACHE_HOME=str(home / '.cache'),
                       PATH=str(bin_dir) + ':' + os.environ['PATH'])
            env.pop('DBUS_SESSION_BUS_ADDRESS', None)
            result = subprocess.run(['dbus-run-session', '--', 'bash', '-eu', '-c', '''
                bash "$1/scripts/restore.sh"
                test "$(dconf read /org/cinnamon/desktop/interface/icon-theme)" = "'Tela-circle-pink'"
                test -z "$(dconf read /org/cinnamon/muffin/experimental-features)"
                mkdir -p "$HOME/.mozilla/firefox/test.default-release"
                printf '[Profile0]\\nPath=test.default-release\\nIsRelative=1\\nDefault=1\\n' > "$HOME/.mozilla/firefox/profiles.ini"
                printf 'user_pref("unrelated", true);\\n' > "$HOME/.mozilla/firefox/test.default-release/user.js"
                bash "$1/scripts/restore.sh"
                bash "$1/scripts/restore.sh"
                ''', 'test', str(ROOT)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('Firefox profile absent', result.stderr)
            self.assertTrue((home / '.themes/Catppuccin-Pink-Dark-B/index.theme').exists())
            prefs = (home / '.mozilla/firefox/test.default-release/user.js').read_text()
            self.assertEqual(prefs.count('toolkit.legacyUserProfileCustomizations.stylesheets'), 1)
            self.assertIn('unrelated', prefs)
            spice = json.loads((home / '.config/cinnamon/spices/CommandRunner@appdevsw/16.json').read_text())
            self.assertIn(str(home), spice['form_command']['value'])
            self.assertTrue((home / 'Templates/vpn-status.sh').stat().st_mode & 0o111)
            backups = list(home.glob('.mint-rice-before-restore.*'))
            self.assertEqual(len(backups), 3)
            self.assertTrue(any((p / '.mozilla/firefox/test.default-release/user.js').exists() for p in backups))


if __name__ == '__main__':
    unittest.main()
