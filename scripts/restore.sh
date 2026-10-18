#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

if [[ "${1:-}" == --help ]]; then
    echo 'Usage: restore.sh [--install-packages]'
    echo 'Run as your normal user inside a Cinnamon desktop session, NOT with sudo.'
    exit 0
fi
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --install-packages ) ]]; then
    echo 'Unknown option; use --help' >&2; exit 2
fi
if [[ $EUID -eq 0 ]]; then
    echo 'Do not run restore with sudo/root.' >&2; exit 1
fi
if [[ "${1:-}" == --install-packages ]]; then
    "$ROOT/scripts/install-packages.sh"
fi
command -v python3 >/dev/null || { echo 'Install python3 first.' >&2; exit 1; }
if ! command -v dconf >/dev/null || [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    echo 'Run inside your desktop session with dconf-cli installed.' >&2; exit 1
fi
# Check the session bus before touching existing configuration.
dconf dump /org/cinnamon/ >/dev/null

BACKUP="$(mktemp -d "$HOME/.mint-rice-before-restore.XXXXXXXX")"
echo "Restoring from $ROOT"
echo "Previous files/settings: $BACKUP"
dconf dump /org/cinnamon/ > "$BACKUP/cinnamon.dconf"
dconf dump /net/launchpad/plank/ > "$BACKUP/plank.dconf"
WARNINGS=0
warn() { echo "  ! $*" >&2; WARNINGS=$((WARNINGS + 1)); }
save() {
    local dst="$1" relative="${1#"$HOME/"}"
    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP/$(dirname "$relative")"
        cp -a "$dst" "$BACKUP/$relative"
    fi
}
copy_file() {
    local src="$1" dst="$2"
    [[ -f "$src" ]] || { warn "Missing file: $src"; return; }
    save "$dst"
    mkdir -p "$(dirname "$dst")"
    # Avoid following a pre-existing destination symlink.
    rm -f "$dst"
    cp -a "$src" "$dst"
}
copy_dir() {
    local src="$1" dst="$2"
    [[ -d "$src" ]] || { warn "Missing directory: $src"; return; }
    save "$dst"
    mkdir -p "$(dirname "$dst")"
    # Replace only this known configuration directory; the old copy is saved above.
    rm -rf -- "$dst"
    cp -a "$src" "$dst"
}
portable_file() {
    local kind="$1" src="$2" dst="$3"
    [[ -f "$src" ]] || { warn "Missing file: $src"; return; }
    save "$dst"
    mkdir -p "$(dirname "$dst")"
    rm -f "$dst"
    python3 "$ROOT/scripts/portable.py" restore "$kind" "$src" "$dst"
}

copy_file "$ROOT/wallpapers/wallpaper-5k.png" "$HOME/Pictures/wallpaper-5k.png"
copy_file "$ROOT/wallpapers/telegram-wallpaper.png" "$HOME/Pictures/telegram-wallpaper.png"
copy_file "$ROOT/configs/scripts/vpn-toggle.sh" "$HOME/Templates/vpn-toggle.sh"
copy_file "$ROOT/configs/scripts/vpn-status.sh" "$HOME/Templates/vpn-status.sh"
chmod +x "$HOME/Templates/vpn-toggle.sh" "$HOME/Templates/vpn-status.sh"
portable_file zsh "$ROOT/configs/zsh/zshrc" "$HOME/.zshrc"
copy_file "$ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"
copy_dir "$ROOT/configs/kitty" "$HOME/.config/kitty"
copy_dir "$ROOT/configs/btop" "$HOME/.config/btop"
copy_dir "$ROOT/themes/gtk/Catppuccin-Pink-Dark-B" "$HOME/.themes/Catppuccin-Pink-Dark-B"
copy_dir "$ROOT/themes/icons/Tela-circle-pink" "$HOME/.local/share/icons/Tela-circle-pink"
if [[ -d "$ROOT/themes/icons/hellokitty" ]]; then
    copy_dir "$ROOT/themes/icons/hellokitty" "$HOME/.local/share/icons/hellokitty"
fi
copy_dir "$ROOT/themes/cursors/catppuccin-mocha-pink-cursors" "$HOME/.icons/catppuccin-mocha-pink-cursors"

# Copy each spice separately: do not delete unrelated installed applets/extensions.
for kind in applets extensions desklets; do
    if [[ -d "$ROOT/configs/cinnamon/$kind" ]]; then
        for src in "$ROOT/configs/cinnamon/$kind/"*; do
            [[ -d "$src" ]] || continue
            copy_dir "$src" "$HOME/.local/share/cinnamon/$kind/$(basename "$src")"
        done
    fi
done
if [[ -d "$ROOT/configs/cinnamon/spices" ]]; then
    for src in "$ROOT/configs/cinnamon/spices/"*; do
        [[ -d "$src" ]] || continue
        dst="$HOME/.config/cinnamon/spices/$(basename "$src")"
        copy_dir "$src" "$dst"
        for settings in "$dst/"*.json; do
            [[ -f "$settings" ]] || continue
            python3 "$ROOT/scripts/portable.py" restore spices "$settings" "$settings"
        done
    done
else
    warn 'No Cinnamon spice instance settings in snapshot; applets will use defaults.'
fi
python3 "$ROOT/scripts/portable.py" restore cinnamon \
    "$ROOT/configs/cinnamon/cinnamon.dconf" "$BACKUP/cinnamon-applied.dconf"
dconf load /org/cinnamon/ < "$BACKUP/cinnamon-applied.dconf"

copy_dir "$ROOT/configs/plank/Catppuccin-mocha" "$HOME/.local/share/plank/themes/Catppuccin-mocha"
if [[ -d "$ROOT/configs/plank/launchers" ]]; then
    copy_dir "$ROOT/configs/plank/launchers" "$HOME/.config/plank/dock1/launchers"
    for launcher in "$HOME/.config/plank/dock1/launchers/"*.dockitem; do
        [[ -f "$launcher" ]] || continue
        python3 "$ROOT/scripts/portable.py" restore launcher "$launcher" "$launcher"
    done
else
    warn 'No Plank launchers in snapshot; pin applications to the dock manually.'
fi
python3 "$ROOT/scripts/portable.py" restore plank \
    "$ROOT/configs/plank/plank.dconf" "$BACKUP/plank-applied.dconf"
dconf load /net/launchpad/plank/ < "$BACKUP/plank-applied.dconf"
# Mint does not start Plank by default.
if command -v plank >/dev/null; then
    mkdir -p "$HOME/.config/autostart"
    save "$HOME/.config/autostart/mint-rice-plank.desktop"
    rm -f "$HOME/.config/autostart/mint-rice-plank.desktop"
    cat > "$HOME/.config/autostart/mint-rice-plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF
fi

portable_file vscode "$ROOT/configs/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
copy_file "$ROOT/configs/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
if command -v code >/dev/null; then
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        [[ -z "$extension" || "$extension" == \#* ]] && continue
        code --install-extension "$extension" || warn "VS Code extension failed: $extension"
    done < "$ROOT/configs/vscode/extensions.txt"
else
    warn 'VS Code not installed; settings copied, rerun restore after installation for extensions.'
fi

# Do not replace a working local Spicetify installation's state with old versions.
if [[ ! -e "$HOME/.config/spicetify/config-xpui.ini" ]]; then
    portable_file spicetify "$ROOT/configs/spicetify/config-xpui.ini" "$HOME/.config/spicetify/config-xpui.ini"
fi
if [[ -d "$ROOT/configs/spicetify/Themes" ]]; then
    for src in "$ROOT/configs/spicetify/Themes/"*; do
        [[ -d "$src" ]] || continue
        copy_dir "$src" "$HOME/.config/spicetify/Themes/$(basename "$src")"
    done
fi
warn 'Spotify/Spicetify and Marketplace require separate installation and setup (see README).'

FF_PROFILE="$(python3 "$ROOT/scripts/portable.py" firefox)"
if [[ -n "$FF_PROFILE" ]]; then
    copy_dir "$ROOT/configs/firefox/chrome" "$FF_PROFILE/chrome"
    save "$FF_PROFILE/user.js"
    # Preserve unrelated preferences and make repeated restores idempotent.
    python3 - "$FF_PROFILE/user.js" <<'PY'
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
text = p.read_text() if p.exists() else ''
text = re.sub(r'^.*user_pref\("toolkit\.legacyUserProfileCustomizations\.stylesheets".*\n?', '', text, flags=re.M)
if p.is_symlink():
    p.unlink()
p.write_text(text.rstrip() + '\nuser_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n')
PY
else
    warn 'Firefox profile absent or ambiguous. Launch and close Firefox, then rerun restore (see README).'
fi
for cmd in kitty btop zsh starship plank; do
    command -v "$cmd" >/dev/null || warn "Not installed: $cmd"
done
if ! fc-match 'JetBrainsMono Nerd Font' 2>/dev/null | grep -qi 'JetBrains.*Nerd'; then
    warn 'JetBrainsMono Nerd Font is missing; install it as described in README.'
fi
echo "Restore finished with $WARNINGS warning(s). Previous settings: $BACKUP"
echo 'Log out and back in. Zsh login shell: chsh -s "$(command -v zsh)" (optional).'
