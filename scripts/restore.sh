#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================"
echo " Mint Rice Restore"
echo "======================================"
echo
echo "Source: $ROOT"
echo

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
  "$HOME/Pictures"

echo "==> Zsh"
cp -a "$ROOT/configs/zsh/zshrc" "$HOME/.zshrc"

echo "==> Starship"
mkdir -p "$HOME/.config"
cp -a "$ROOT/configs/starship/starship.toml" \
      "$HOME/.config/starship.toml"

echo "==> Kitty"
cp -a "$ROOT/configs/kitty/." "$HOME/.config/kitty/"

echo "==> btop"
cp -a "$ROOT/configs/btop/." "$HOME/.config/btop/"

echo "==> VS Code"
cp -a "$ROOT/configs/vscode/settings.json" \
      "$HOME/.config/Code/User/settings.json"

if [[ -f "$ROOT/configs/vscode/keybindings.json" ]]; then
    cp -a "$ROOT/configs/vscode/keybindings.json" \
          "$HOME/.config/Code/User/keybindings.json"
fi

if command -v code >/dev/null 2>&1; then
    echo "==> VS Code extensions"

    while IFS= read -r ext; do
        [[ -z "$ext" ]] && continue
        echo "    $ext"
        code --install-extension "$ext" --force || true
    done < "$ROOT/configs/vscode/extensions.txt"
fi

echo "==> GTK theme"
rm -rf "$HOME/.themes/Catppuccin-Pink-Dark-B"
cp -a "$ROOT/themes/gtk/Catppuccin-Pink-Dark-B" \
      "$HOME/.themes/"

echo "==> Tela icons"
rm -rf "$HOME/.local/share/icons/Tela-circle-pink"
cp -a "$ROOT/themes/icons/Tela-circle-pink" \
      "$HOME/.local/share/icons/"

echo "==> Catppuccin cursor"
rm -rf "$HOME/.icons/catppuccin-mocha-pink-cursors"
cp -a "$ROOT/themes/cursors/catppuccin-mocha-pink-cursors" \
      "$HOME/.icons/"

echo "==> Cinnamon applets"

if [[ -d "$ROOT/configs/cinnamon/applets" ]]; then
    cp -a "$ROOT/configs/cinnamon/applets/." \
          "$HOME/.local/share/cinnamon/applets/"
fi

if [[ -d "$ROOT/configs/cinnamon/extensions" ]]; then
    cp -a "$ROOT/configs/cinnamon/extensions/." \
          "$HOME/.local/share/cinnamon/extensions/"
fi

echo "==> Cinnamon settings"

if command -v dconf >/dev/null 2>&1; then
    dconf load /org/cinnamon/ \
        < "$ROOT/configs/cinnamon/cinnamon.dconf"
fi

echo "==> Plank theme"

if [[ -d "$ROOT/configs/plank/Catppuccin-mocha" ]]; then
    rm -rf "$HOME/.local/share/plank/themes/Catppuccin-mocha"

    cp -a "$ROOT/configs/plank/Catppuccin-mocha" \
          "$HOME/.local/share/plank/themes/"
fi

if command -v dconf >/dev/null 2>&1 && \
   [[ -f "$ROOT/configs/plank/plank.dconf" ]]; then

    dconf load /net/launchpad/plank/ \
        < "$ROOT/configs/plank/plank.dconf"
fi

echo "==> Spicetify"

if [[ -f "$ROOT/configs/spicetify/config-xpui.ini" ]]; then
    cp -a "$ROOT/configs/spicetify/config-xpui.ini" \
          "$HOME/.config/spicetify/config-xpui.ini"
fi

if [[ -d "$ROOT/configs/spicetify/Themes" ]]; then
    rm -rf "$HOME/.config/spicetify/Themes"
    cp -a "$ROOT/configs/spicetify/Themes" \
          "$HOME/.config/spicetify/"
fi

echo "==> Firefox FlexFox"

FF_PROFILE="$(find "$HOME/.config/mozilla/firefox" \
    -maxdepth 1 -type d -name '*.default-release' \
    2>/dev/null | head -1)"

if [[ -n "${FF_PROFILE:-}" && -d "$ROOT/configs/firefox/chrome" ]]; then
    rm -rf "$FF_PROFILE/chrome"
    cp -a "$ROOT/configs/firefox/chrome" "$FF_PROFILE/"
    echo "    Firefox profile: $FF_PROFILE"
else
    echo "    Firefox profile not found - skipped."
fi

echo "==> Wallpapers"

cp -a "$ROOT/wallpapers/." "$HOME/Pictures/"

echo
echo "======================================"
echo " User configuration restored."
echo "======================================"
echo
echo "Still requires system setup:"
echo "  - APT packages/repos"
echo "  - Flatpak applications"
echo "  - JetBrainsMono Nerd Font"
echo "  - LightDM system configuration"
echo "  - Spotify/Spicetify permissions"
echo
echo "Log out/in after restoring Cinnamon."
