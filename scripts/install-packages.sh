#!/usr/bin/env bash
# Explicit opt-in only. Never replay a full inventory or import old APT sources.
set -euo pipefail
if [[ $EUID -eq 0 ]]; then
    echo 'Run as your normal user; sudo is used for APT only.' >&2; exit 1
fi
source /etc/os-release
if [[ "${ID:-}" != linuxmint || "${VERSION_ID%%.*}" != 22 ]]; then
    echo 'Automatic package installation is supported on Linux Mint 22.x only.' >&2
    exit 1
fi
sudo apt-get update
sudo apt-get install -y python3 dconf-cli dbus-user-session fontconfig \
    kitty btop zsh zsh-autosuggestions zsh-syntax-highlighting \
    plank firefox curl ca-certificates unzip gtk2-engines-murrine gtk2-engines-pixbuf

export PATH="$HOME/.local/bin:$PATH"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
if ! command -v starship >/dev/null; then
    case "$(uname -m)" in
        x86_64) target=x86_64-unknown-linux-musl ;;
        aarch64) target=aarch64-unknown-linux-musl ;;
        *) echo 'Unsupported architecture for Starship binary.' >&2; exit 1 ;;
    esac
    curl --fail --location --retry 3 \
        "https://github.com/starship/starship/releases/latest/download/starship-$target.tar.gz" \
        -o "$TMP/starship.tar.gz"
    tar -xOf "$TMP/starship.tar.gz" starship > "$TMP/starship"
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$TMP/starship" "$HOME/.local/bin/starship"
fi
if ! fc-match 'JetBrainsMono Nerd Font' | grep -qi 'JetBrains.*Nerd'; then
    curl --fail --location --retry 3 \
        'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip' \
        -o "$TMP/font.zip"
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
    unzip -jo "$TMP/font.zip" '*.ttf' -d "$HOME/.local/share/fonts/JetBrainsMono"
    fc-cache -f "$HOME/.local/share/fonts/JetBrainsMono"
fi
echo 'Core packages, Starship and Nerd Font installed. Optional applications: see README.'
