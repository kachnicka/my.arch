#!/bin/bash

# Package/system cache maintenance. Idempotent and network-free:
# safe to re-run any time on a live system (also called from arch_init.sh
# on fresh installs). No timers/crons are added here.
#
# usage: sudo maintenance.sh [username]

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# target user for AUR cache cleanup: argument, else sudo caller, else first
# regular login user
USERNAME="$1"
if [ -z "$USERNAME" ] || [ "$USERNAME" = "root" ]; then
    USERNAME="${SUDO_USER:-}"
fi
if [ -z "$USERNAME" ] || [ "$USERNAME" = "root" ]; then
    USERNAME=$(awk -F: '$3>=1000 && $3<60000 {print $1; exit}' /etc/passwd)
fi
if [ -z "$USERNAME" ] || ! id "$USERNAME" &>/dev/null; then
    echo " Error: no regular user found for AUR cache cleanup" >&2
    exit 1
fi

echo -e "\nConfigure: paccache timer args"
# timer default (paccache -r) keeps 3 versions of installed pkgs only and never
# removes tarballs of uninstalled pkgs; -ruk2 also drops those, keeps 2 versions
PACCACHE_CONF="/etc/conf.d/pacman-contrib"
if command -v paccache >/dev/null 2>&1; then
    if grep -q '^PACCACHE_ARGS="-ruk2"$' "$PACCACHE_CONF" 2>/dev/null; then
        echo " there is nothing to do"
    else
        echo " setting PACCACHE_ARGS=-ruk2"
        sed -i 's/^PACCACHE_ARGS=.*/PACCACHE_ARGS="-ruk2"/' "$PACCACHE_CONF"
    fi
    systemctl enable paccache.timer >/dev/null 2>&1 || true
else
    echo " Warning: pacman-contrib not installed, skipping paccache" >&2
fi

echo -e "\nClean: pacman package cache"
paccache -ruk2

echo -e "\nClean: AUR build cache (user '$USERNAME')"
# AUR build cache (old tarballs, e.g. clion/brave-bin) lives in ~/.cache/yay
if runuser -u "$USERNAME" -- bash -c 'command -v yay' >/dev/null 2>&1; then
    runuser -u "$USERNAME" -- yay -Sc --noconfirm
else
    echo " yay not found for '$USERNAME', nothing to do"
fi

echo -e "\nClean: systemd journal (keep 30 days)"
journalctl --vacuum-time=30d 2>/dev/null || echo " Warning: journal vacuum failed" >&2
