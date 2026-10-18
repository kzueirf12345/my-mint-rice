#!/usr/bin/env python3
"""Portable, credential-free configuration transforms shared by backup/restore."""
import configparser
import json
import os
from pathlib import Path
import re
import sys
from urllib.parse import unquote


def firefox_profile(home):
    """Prefer installation defaults, then profile defaults, then a sole profile.

    Never guess between multiple profiles and never create an unregistered one.
    """
    for root in (home / '.mozilla/firefox', home / '.config/mozilla/firefox',
                 home / '.var/app/org.mozilla.firefox/.mozilla/firefox'):
        parser = configparser.RawConfigParser()
        parser.read(root / 'profiles.ini')
        candidates = []
        installs = configparser.RawConfigParser()
        installs.read(root / 'installs.ini')
        for source in (installs, parser):
            for section in source.sections():
                if not section.startswith('Profile') and source.has_option(section, 'Default'):
                    path = Path(source.get(section, 'Default'))
                    path = path if path.is_absolute() else root / path
                    if path.is_dir():
                        return path.resolve()
        for section in parser.sections():
            if not section.startswith('Profile') or not parser.has_option(section, 'Path'):
                continue
            path = Path(parser.get(section, 'Path'))
            if parser.get(section, 'IsRelative', fallback='1') == '1':
                path = root / path
            if path.is_dir():
                if parser.get(section, 'Default', fallback='0') == '1':
                    return path.resolve()
                candidates.append(path)
        if len(candidates) == 1:
            return candidates[0].resolve()
    return None


def transform(kind, text, home, restore=False):
    if kind == 'spices':
        data = json.loads(text)
        # Values-only files are upgraded against the installed spice schema by
        # Cinnamon itself. Omitting __md5__ deliberately requests this upgrade.
        data = {key: {'value': value['value']} for key, value in data.items()
                if isinstance(value, dict) and 'value' in value
                and key not in ('recent-apps', 'folder-categories')}
        def paths(value):
            if isinstance(value, str):
                return value.replace('@HOME@', str(home)) if restore else value.replace(str(home), '@HOME@')
            if isinstance(value, list):
                return [paths(item) for item in value]
            if isinstance(value, dict):
                return {key: paths(item) for key, item in value.items()}
            return value
        return json.dumps(paths(data), ensure_ascii=False, indent=2) + '\n'
    if kind == 'cinnamon':
        # Hardware, accessibility, input and power settings stay local.
        allowed = {'/', 'desktop/applications/calculator', 'desktop/applications/terminal',
                   'desktop/background', 'desktop/interface', 'desktop/keybindings',
                   'desktop/keybindings/media-keys', 'desktop/keybindings/wm',
                   'desktop/wm/preferences', 'theme'}
        section = None
        lines = []
        for line in text.splitlines():
            if line.startswith('['):
                section = line[1:-1]
            if section not in allowed and not (section or '').startswith('desktop/keybindings/custom-keybindings/'):
                continue
            if re.match(r'(command-history|text-scaling-factor|gtk-theme-backup|icon-theme-backup|theme-backup)=', line):
                continue
            line = re.sub(r'file:///home/[^/]+/Pictures/wallpaper-5k.png',
                          'file://@HOME@/Pictures/wallpaper-5k.png', line)
            line = re.sub(r'/home/[^/]+/Templates/vpn-toggle.sh', '@HOME@/Templates/vpn-toggle.sh', line)
            # The repository ships the regular Tela variant, not the dark variant.
            line = line.replace("icon-theme='Tela-circle-pink-dark'", "icon-theme='Tela-circle-pink'")
            lines.append(line)
        text = '\n'.join(lines) + '\n'
    elif kind == 'plank':
        text = '\n'.join(line for line in text.splitlines()
                         if not re.match(r'(monitor|active-display)=', line)) + '\n'
    elif kind == 'launcher' and restore:
        # Distribution and Flatpak packages may use different desktop filenames.
        match = re.search(r'(?m)^Launcher=file://(.+)$', text)
        if match:
            original = Path(unquote(match.group(1).replace('@HOME@', str(home))))
            aliases = {
                'com.microsoft.VSCode.desktop': ('code.desktop', 'com.visualstudio.code.desktop'),
                'org.telegram.desktop.desktop': ('telegramdesktop.desktop', 'org.telegram.desktop.desktop'),
                'firefox.desktop': ('org.mozilla.firefox.desktop',),
                'spotify.desktop': ('com.spotify.Client.desktop',),
            }
            directories = [home / '.local/share/applications',
                           home / '.local/share/flatpak/exports/share/applications',
                           Path('/usr/local/share/applications'), Path('/usr/share/applications'),
                           Path('/var/lib/flatpak/exports/share/applications')]
            candidates = [original] + [directory / name for directory in directories
                                       for name in (original.name, *aliases.get(original.name, ()))]
            chosen = next((path for path in candidates if path.is_file()), None)
            if chosen:
                text = text[:match.start()] + 'Launcher=' + chosen.as_uri() + text[match.end():]
    elif kind == 'spicetify':
        # Marketplace assets and Spotify backups are NOT part of this snapshot.
        text = re.sub(r'(?m)^current_theme\s*=.*$', 'current_theme = ', text)
        text = re.sub(r'(?m)^custom_apps\s*=.*$', 'custom_apps = ', text)
        text = re.sub(r'(?ms)^\[Backup\].*\Z', '', text)
        text = re.sub(r'(?m)^prefs_path\s*=.*$', 'prefs_path = @HOME@/.config/spotify/prefs', text)
    elif kind == 'zsh':
        text = re.sub(r'/home/[^/]+/\.opencode', '$HOME/.opencode', text)
    elif kind == 'vscode':
        # VS Code JSONC: remove only the machine-local override, preserve comments.
        text = re.sub(r'(?m)^\s*"clangd.path"\s*:.*\n', '', text)
    # Normalize the current user's home as well as the original snapshot's home.
    text = text.replace(str(home), '@HOME@') if not restore else text
    if restore:
        escaped = str(home).replace('\\', '\\\\').replace("'", "\\'")
        text = text.replace('@HOME@', escaped if kind == 'cinnamon' else str(home))
    return text


def main():
    mode, *args = sys.argv[1:]
    home = Path(os.environ['HOME'])
    if mode == 'firefox':
        profile = firefox_profile(home)
        if profile:
            print(profile)
        return
    kind, source, dest = args
    text = Path(source).read_text()
    Path(dest).write_text(transform(kind, text, home, mode == 'restore'))


if __name__ == '__main__':
    main()
