#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================"
echo " Mint Rice Restore"
echo "======================================"
echo "Source: $ROOT"
echo "Home:   $HOME"
echo

copy_file() {
    local src="$1"
    local dst="$2"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "  + $dst"
    fi
}

copy_dir_contents() {
    local src="$1"
    local dst="$2"

    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
        echo "  + $dst"
    fi
}

echo "==> Creating directories"

mkdir -p \
    "$HOME/.config/kitty" \
    "$HOME/.config/btop" \
    "$HOME/.config/Code/User" \
    "$HOME/.config/spicetify" \
    "$HOME/.local/share/plank/themes" \
    "$HOME/.local/share/cinnamon/applets" \
    "$HOME/.local/share/cinnamon/extensions" \
    "$HOME/.local/share/icons" \
    "$HOME/.themes" \
    "$HOME/.icons" \
    "$HOME/Pictures" \
    "$HOME/Templates"

echo
echo "==> Wallpapers"

copy_file \
    "$ROOT/wallpapers/wallpaper-5k.png" \
    "$HOME/Pictures/wallpaper-5k.png"

copy_file \
    "$ROOT/wallpapers/telegram-wallpaper.png" \
    "$HOME/Pictures/telegram-wallpaper.png"

echo
echo "==> User scripts"

if [[ -f "$ROOT/configs/scripts/vpn-toggle.sh" ]]; then
    copy_file \
        "$ROOT/configs/scripts/vpn-toggle.sh" \
        "$HOME/Templates/vpn-toggle.sh"

    chmod +x "$HOME/Templates/vpn-toggle.sh"
fi

echo
echo "==> Zsh"

copy_file \
    "$ROOT/configs/zsh/zshrc" \
    "$HOME/.zshrc"

echo
echo "==> Starship"

copy_file \
    "$ROOT/configs/starship/starship.toml" \
    "$HOME/.config/starship.toml"

echo
echo "==> Kitty"

copy_dir_contents \
    "$ROOT/configs/kitty" \
    "$HOME/.config/kitty"

echo
echo "==> btop"

copy_dir_contents \
    "$ROOT/configs/btop" \
    "$HOME/.config/btop"

echo
echo "==> GTK theme"

if [[ -d "$ROOT/themes/gtk/Catppuccin-Pink-Dark-B" ]]; then
    rm -rf "$HOME/.themes/Catppuccin-Pink-Dark-B"

    cp -a \
        "$ROOT/themes/gtk/Catppuccin-Pink-Dark-B" \
        "$HOME/.themes/"
fi

echo
echo "==> Icons"

if [[ -d "$ROOT/themes/icons/Tela-circle-pink" ]]; then
    rm -rf "$HOME/.local/share/icons/Tela-circle-pink"

    cp -a \
        "$ROOT/themes/icons/Tela-circle-pink" \
        "$HOME/.local/share/icons/"
fi

echo
echo "==> Cursor"

if [[ -d "$ROOT/themes/cursors/catppuccin-mocha-pink-cursors" ]]; then
    rm -rf "$HOME/.icons/catppuccin-mocha-pink-cursors"

    cp -a \
        "$ROOT/themes/cursors/catppuccin-mocha-pink-cursors" \
        "$HOME/.icons/"
fi

echo
echo "==> Cinnamon applets"

copy_dir_contents \
    "$ROOT/configs/cinnamon/applets" \
    "$HOME/.local/share/cinnamon/applets"

copy_dir_contents \
    "$ROOT/configs/cinnamon/extensions" \
    "$HOME/.local/share/cinnamon/extensions"

echo
echo "==> Cinnamon settings"

if command -v dconf >/dev/null 2>&1 &&
   [[ -f "$ROOT/configs/cinnamon/cinnamon.dconf" ]]; then

    TMP_CINNAMON="$(mktemp)"
    trap 'rm -f "$TMP_CINNAMON"' EXIT

    sed \
        -e "s#file:///home/urodish/Pictures/wallpaper-5k.png#file://$HOME/Pictures/wallpaper-5k.png#g" \
        -e "s#/home/urodish/Templates/vpn-toggle.sh#$HOME/Templates/vpn-toggle.sh#g" \
        "$ROOT/configs/cinnamon/cinnamon.dconf" \
        > "$TMP_CINNAMON"

    dconf load /org/cinnamon/ < "$TMP_CINNAMON"

    rm -f "$TMP_CINNAMON"
    trap - EXIT
else
    echo "  ! dconf unavailable - skipped"
fi

echo
echo "==> Plank"

if [[ -d "$ROOT/configs/plank/Catppuccin-mocha" ]]; then
    rm -rf "$HOME/.local/share/plank/themes/Catppuccin-mocha"

    cp -a \
        "$ROOT/configs/plank/Catppuccin-mocha" \
        "$HOME/.local/share/plank/themes/"
fi

if command -v dconf >/dev/null 2>&1 &&
   [[ -f "$ROOT/configs/plank/plank.dconf" ]]; then

    dconf load /net/launchpad/plank/ \
        < "$ROOT/configs/plank/plank.dconf"
fi

echo
echo "==> VS Code"

copy_file \
    "$ROOT/configs/vscode/settings.json" \
    "$HOME/.config/Code/User/settings.json"

copy_file \
    "$ROOT/configs/vscode/keybindings.json" \
    "$HOME/.config/Code/User/keybindings.json"

if command -v code >/dev/null 2>&1 &&
   [[ -f "$ROOT/configs/vscode/extensions.txt" ]]; then

    echo "  Installing VS Code extensions..."

    while IFS= read -r extension; do
        [[ -z "$extension" ]] && continue
        code --install-extension "$extension" --force || true
    done < "$ROOT/configs/vscode/extensions.txt"
fi

echo
echo "==> Spicetify"

copy_file \
    "$ROOT/configs/spicetify/config-xpui.ini" \
    "$HOME/.config/spicetify/config-xpui.ini"

copy_dir_contents \
    "$ROOT/configs/spicetify/Themes" \
    "$HOME/.config/spicetify/Themes"

echo
echo "==> Firefox / FlexFox"

FIREFOX_ROOT="$HOME/.config/mozilla/firefox"
FF_PROFILE=""

if [[ -f "$FIREFOX_ROOT/profiles.ini" ]]; then
    PROFILE_PATH="$(
        awk -F= '
            /^\[Profile/ { path=""; def=0 }
            /^Path=/ { path=$2 }
            /^Default=1/ { def=1 }
            /^$/ {
                if (def && path != "") {
                    print path
                    exit
                }
            }
            END {
                if (def && path != "") print path
            }
        ' "$FIREFOX_ROOT/profiles.ini" | head -1
    )"

    if [[ -n "$PROFILE_PATH" ]]; then
        FF_PROFILE="$FIREFOX_ROOT/$PROFILE_PATH"
    fi
fi

if [[ -z "$FF_PROFILE" || ! -d "$FF_PROFILE" ]]; then
    FF_PROFILE="$(
        find "$FIREFOX_ROOT" \
            -maxdepth 1 \
            -type d \
            -name '*.default-release' \
            2>/dev/null |
        head -1
    )"
fi

if [[ -n "$FF_PROFILE" &&
      -d "$FF_PROFILE" &&
      -d "$ROOT/configs/firefox/chrome" ]]; then

    rm -rf "$FF_PROFILE/chrome"

    cp -a \
        "$ROOT/configs/firefox/chrome" \
        "$FF_PROFILE/"

    echo "  + FlexFox -> $FF_PROFILE"
else
    echo "  ! Firefox profile not found - skipped"
fi

echo
echo "======================================"
echo " User-level restore complete"
echo "======================================"
echo
echo "Manual/system-level steps may remain:"
echo "  - install APT packages"
echo "  - install Flatpak applications"
echo "  - install JetBrainsMono Nerd Font"
echo "  - configure LightDM"
echo "  - configure Spotify/Spicetify"
echo "  - review monitor-specific settings"
echo
echo "Log out and back in after restoring Cinnamon."
