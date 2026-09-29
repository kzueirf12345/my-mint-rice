#!/bin/bash
if ip link show Netherlands >/dev/null 2>&1; then
    sudo awg-quick down Netherlands
else
    sudo awg-quick up Netherlands
fi
