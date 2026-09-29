#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Backing up rice to:"
echo "    $ROOT"

mkdir -p \
  "$ROOT/configs"/{zsh,starship,kitty,btop,vscode,spicetify,plank,cinnamon,lightdm,firefox} \
  "$ROOT/themes"/{gtk,icons,cursors} \
  "$ROOT/wallpapers" \
  "$ROOT/system"/{apt,flatpak,gsettings,fonts}

copy_file() {
    src="$1"
    dst="$2"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "  + $src"
    fi
}

copy_dir() {
    src="$1"
    dst="$2"

    if [[ -d "$src" ]]; then
        rm -rf "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "  + $src"
    fi
}

echo
echo "==> Shell"
copy_file "$HOME/.zshrc" \
          "$ROOT/configs/zsh/zshrc"

copy_file "$HOME/.config/starship.toml" \
          "$ROOT/configs/starship/starship.toml"

echo
echo "==> Kitty"
copy_file "$HOME/.config/kitty/kitty.conf" \
          "$ROOT/configs/kitty/kitty.conf"

if [[ -d "$HOME/.config/kitty" ]]; then
    find "$HOME/.config/kitty" -maxdepth 1 -type f \
        ! -name kitty.conf \
        -exec cp -a {} "$ROOT/configs/kitty/" \;
fi

echo
echo "==> btop"
copy_file "$HOME/.config/btop/btop.conf" \
          "$ROOT/configs/btop/btop.conf"

if [[ -d "$HOME/.config/btop/themes" ]]; then
    copy_dir "$HOME/.config/btop/themes" \
             "$ROOT/configs/btop/themes"
fi

echo
echo "==> VS Code"
copy_file "$HOME/.config/Code/User/settings.json" \
          "$ROOT/configs/vscode/settings.json"

copy_file "$HOME/.config/Code/User/keybindings.json" \
          "$ROOT/configs/vscode/keybindings.json"

if command -v code >/dev/null 2>&1; then
    code --list-extensions | sort \
        > "$ROOT/configs/vscode/extensions.txt"
fi

echo
echo "==> Spicetify"
copy_file "$HOME/.config/spicetify/config-xpui.ini" \
          "$ROOT/configs/spicetify/config-xpui.ini"

if [[ -d "$HOME/.config/spicetify/Themes" ]]; then
    copy_dir "$HOME/.config/spicetify/Themes" \
             "$ROOT/configs/spicetify/Themes"
fi

echo
echo "==> Plank"
if [[ -d "$HOME/.local/share/plank/themes/Catppuccin-mocha" ]]; then
    copy_dir "$HOME/.local/share/plank/themes/Catppuccin-mocha" \
             "$ROOT/configs/plank/Catppuccin-mocha"
fi

dconf dump /net/launchpad/plank/ \
    > "$ROOT/configs/plank/plank.dconf" 2>/dev/null || true

echo
echo "==> Cinnamon"

dconf dump /org/cinnamon/ \
    > "$ROOT/configs/cinnamon/cinnamon.dconf" 2>/dev/null || true

gsettings get org.cinnamon enabled-applets \
    > "$ROOT/configs/cinnamon/enabled-applets.txt" 2>/dev/null || true

gsettings get org.cinnamon enabled-desklets \
    > "$ROOT/configs/cinnamon/enabled-desklets.txt" 2>/dev/null || true

gsettings get org.cinnamon enabled-extensions \
    > "$ROOT/configs/cinnamon/enabled-extensions.txt" 2>/dev/null || true

if [[ -d "$HOME/.local/share/cinnamon/applets" ]]; then
    copy_dir "$HOME/.local/share/cinnamon/applets" \
             "$ROOT/configs/cinnamon/applets"
fi

if [[ -d "$HOME/.local/share/cinnamon/extensions" ]]; then
    copy_dir "$HOME/.local/share/cinnamon/extensions" \
             "$ROOT/configs/cinnamon/extensions"
fi

echo
echo "==> LightDM"

if [[ -r /etc/lightdm/slick-greeter.conf ]]; then
    cp -a /etc/lightdm/slick-greeter.conf \
          "$ROOT/configs/lightdm/slick-greeter.conf"
fi

echo
echo "==> GTK theme"

copy_dir "$HOME/.themes/Catppuccin-Pink-Dark-B" \
         "$ROOT/themes/gtk/Catppuccin-Pink-Dark-B"

echo
echo "==> Icons"

copy_dir "$HOME/.local/share/icons/Tela-circle-pink" \
         "$ROOT/themes/icons/Tela-circle-pink"

echo
echo "==> Cursor"

copy_dir "$HOME/.icons/catppuccin-mocha-pink-cursors" \
         "$ROOT/themes/cursors/catppuccin-mocha-pink-cursors"

echo
echo "==> Wallpapers"

copy_file "$HOME/Pictures/wallpaper.png" \
          "$ROOT/wallpapers/wallpaper.png"

copy_file "$HOME/Pictures/wallpaper-5k.png" \
          "$ROOT/wallpapers/wallpaper-5k.png"

copy_file "$HOME/Pictures/tg_wallpapres.png" \
          "$ROOT/wallpapers/telegram-wallpaper.png"

echo
echo "==> APT"

apt-mark showmanual | sort \
    > "$ROOT/system/apt/manual-packages.txt"

dpkg-query -W -f='${binary:Package}\t${Version}\n' \
    | sort > "$ROOT/system/apt/all-packages.txt"

grep -RhvE '^[[:space:]]*(#|$)' \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/* \
    2>/dev/null \
    > "$ROOT/system/apt/sources.txt" || true

echo
echo "==> Flatpak"

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        | sort > "$ROOT/system/flatpak/apps.txt"
fi

echo
echo "==> GSettings"

gsettings list-recursively org.cinnamon \
    > "$ROOT/system/gsettings/cinnamon.txt" 2>/dev/null || true

echo
echo "==> Fonts"

fc-list : family | sort -u \
    > "$ROOT/system/fonts/installed-fonts.txt"

fc-list : family | grep -Ei 'JetBrains|Nerd' | sort -u \
    > "$ROOT/system/fonts/nerd-fonts.txt" || true

echo
echo "==> Firefox / FlexFox"

PROFILE="$HOME/.config/mozilla/firefox/0t81mpn3.default-release"

if [[ -d "$PROFILE/chrome" ]]; then
    copy_dir "$PROFILE/chrome" \
             "$ROOT/configs/firefox/chrome"
fi

# Deliberately NOT backing up the Firefox profile:
# cookies, passwords, sessions, storage, tokens, etc.

echo

echo
echo "==> Portable normalization"

# Spicetify: replace machine-specific HOME with ~
if [[ -f "$ROOT/configs/spicetify/config-xpui.ini" ]]; then
    sed -i \
        "s#$HOME/.config/spotify/prefs#~/.config/spotify/prefs#g" \
        "$ROOT/configs/spicetify/config-xpui.ini"
fi

# btop: use theme name instead of absolute path
if [[ -f "$ROOT/configs/btop/btop.conf" ]]; then
    sed -i \
        -E 's#^color_theme = ".*catppuccin_mocha\.theme"$#color_theme = "catppuccin_mocha"#' \
        "$ROOT/configs/btop/btop.conf"
fi

# Scripts used by Cinnamon / CommandRunner
if [[ -f "$HOME/Templates/vpn-toggle.sh" ]]; then
    mkdir -p "$ROOT/configs/scripts"
    cp -a "$HOME/Templates/vpn-toggle.sh" \
          "$ROOT/configs/scripts/vpn-toggle.sh"
fi

echo "==> Finished."
echo
echo "Snapshot: $(date)"
