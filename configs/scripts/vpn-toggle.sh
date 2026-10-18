#!/usr/bin/env bash
set -euo pipefail
# No VPN credentials are stored in the repository. Interface can be overridden.
interface="${MINT_RICE_VPN_INTERFACE:-Netherlands}"
if ! command -v awg-quick >/dev/null; then
    message='Install AmneziaWG and configure your VPN first (see README).'
    echo "$message" >&2
    command -v notify-send >/dev/null && notify-send 'VPN' "$message"
    exit 1
fi
# Applet/keybinding commands have no terminal for sudo's password prompt.
if [[ ! -t 0 ]]; then
    exec kitty --title VPN bash "$0"
fi
if ip link show "$interface" >/dev/null 2>&1; then
    sudo awg-quick down "$interface"
else
    sudo awg-quick up "$interface"
fi
