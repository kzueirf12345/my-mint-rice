#!/usr/bin/env bash
if ! command -v awg-quick >/dev/null 2>&1; then
    echo '⚪ VPN: not configured'
elif ip link show "${MINT_RICE_VPN_INTERFACE:-Netherlands}" >/dev/null 2>&1; then
    echo '🟢 VPN: ON'
else
    echo '🔴 VPN: OFF'
fi
