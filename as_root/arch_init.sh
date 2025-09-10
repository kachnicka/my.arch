#!/bin/sh

# arch install:
#     NetworkManager
#     GRUB

# expected to run as root right after installation
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

echo -e "\nEdit: /etc/pacman.conf"
PACMAN_FILE="/etc/pacman.conf"
if [ ! -r "$PACMAN_FILE" ]; then
    echo " Error: $PACMAN_FILE can not be accessed" >&2
    exit 1
fi
ADD_MULTILIB=$(grep -c "^\[multilib\]$" "$PACMAN_FILE")
if [ "$ADD_MULTILIB" -eq 0 ]; then
    echo " adding multilib mirrors"
    sed -i '/^#\[multilib\]$/ {N; s/#\[multilib\]\n#Include/\[multilib\]\nInclude/}' "$PACMAN_FILE"
else
    echo " there is nothing to do"
fi
pacman --needed --noconfirm -Syu
pacman --needed --noconfirm -S man-db man-pages

echo -e "\nEdit: /etc/sudoer"
pacman --needed --noconfirm -S sudo
SUDO_FILE="/etc/sudoers"
SUDO_TEMP="/tmp/sudoers.tmp"
SUDO_BAK="/etc/sudoers.bak.$(date +%Y%m%d%H%M%S)"
if [ ! -r "$SUDO_FILE" ]; then
    echo " Error: $SUDO_FILE can not be accessed" >&2
    exit 1
fi
ADD_WHEEL=$(grep -c "^%wheel ALL=(ALL:ALL) ALL$" "$SUDO_FILE")
ADD_TS_TYPE=$(grep -c "^Defaults timestamp_type=global$" "$SUDO_FILE")
ADD_TS_TOUT=$(grep -c "^Defaults timestamp_timeout=10$" "$SUDO_FILE")
if [ "$ADD_WHEEL" -eq 0 ] || [ "$ADD_TS_TYPE" -eq 0 ] || [ "$ADD_TS_TOUT" -eq 0 ]; then
    cp "$SUDO_FILE" "$SUDO_BAK"
    echo " Backup created at $SUDO_BAK"

    cp "$SUDO_FILE" "$SUDO_TEMP"
    chmod 600 "$SUDO_TEMP"
else
    echo " there is nothing to do"
fi
if [ "$ADD_WHEEL" -eq 0 ]; then
    echo " adding %wheel"
    sed -i '/^#.*%wheel ALL=(ALL:ALL) ALL/ s/^#.*%/%/' "$SUDO_TEMP"
fi
if [ "$ADD_TS_TYPE" -eq 0 ]; then
    echo " adding timestamp_type"
    sed -i '/^## Defaults specification/a Defaults timestamp_type=global' "$SUDO_TEMP"
fi
if [ "$ADD_TS_TOUT" -eq 0 ]; then
    echo " adding timestamp_timeout"
    sed -i '/^Defaults timestamp_type=global/a Defaults timestamp_timeout=10' "$SUDO_TEMP"
fi
if [ -r "$SUDO_TEMP" ]; then
    if visudo -c -f "$SUDO_TEMP" > /dev/null 2>&1; then
        cp "$SUDO_TEMP" "$SUDO_FILE"
        chmod 440 "$SUDO_FILE"
    else
        echo " Error: Syntax check failed for $SUDO_TEMP, no changes applied" >&2
        exit 1
    fi
    rm -f "$SUDO_TEMP"
fi

echo -e "\nEdit: /etc/security/faillock.conf"
FAILLOCK_FILE="/etc/security/faillock.conf"
if [ ! -r "$FAILLOCK_FILE" ]; then
    echo " Error: $FAILLOCK_FILE can not be accessed" >&2
    exit 1
fi
MODIFY_DENY=$(grep -c "^deny = .*$" "$FAILLOCK_FILE")
if [ "$MODIFY_DENY" -eq 0 ]; then
    " adding deny = 5"
    sed -i '/^# deny = 3$/ s/# deny = 3/deny = 5/' "$FAILLOCK_FILE"
else
    echo " there is nothing to do"
fi

#

USERNAME="kachnicka"
echo -e "\nAdd: user '$USERNAME'"
pacman --needed --noconfirm -S zsh 
if id "$USERNAME" &>/dev/null; then
    echo " there is nothing to do"
else
    useradd -m -G wheel,games,ftp,http -s /bin/zsh "$USERNAME"
    passwd "$USERNAME"
    echo " added '$USERNAME'"
fi

echo -e "\nAdd: GPU driver"
GPU_INFO=$(lspci | grep -E "VGA|3D")
if echo "$GPU_INFO" | grep -Eqi "AMD|Advanced Micro Devices"; then
    echo " detected: AMD"
    pacman --needed --noconfirm -S mesa lib32-mesa vulkan-radeon
elif echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    echo " detected: NVIDIA"
    echo " NOT IMPLEMENTED/TESTED"
    # pacman --needed --noconfirm -S nvidia nvidia-utils
    exit 1
elif echo "$GPU_INFO" | grep -qi "Intel"; then
    echo " detected: Intel"
    echo " NOT IMPLEMENTED/TESTED"
    # pacman --needed --noconfirm -S mesa
    exit 1
else
    echo " detected: nothing"
    echo " there is nothing to do"
fi

echo -e "\nAdd: NTP clock sync"
if timedatectl show | grep -q "NTPSynchronized=no"; then
    timedatectl set-ntp true
    if [ ! $? -eq 0 ]; then
        echo " Failed to enable NTP sync."
        exit 1
    fi
else
    echo " NTP sync is enabled."
fi

echo -e "\nAdd: Audio stack"
pacman --needed --noconfirm -S rtkit
systemctl enable rtkit-daemon.service

echo -e "\nAdd: Hyprland"
# TODO: uwsm for user now, maybe greetd+tuigreet later?
pacman --needed --noconfirm -S hyprland uwsm xdg-user-dirs
PROFILE_FILE="/home/$USERNAME/.zprofile"
if [ ! -f "$PROFILE_FILE" ]; then
    echo " adding $PROFILE_FILE"
    #echo -E "if uwsm check may-start && uwsm select; then\n  exec uwsm start default\nfi" > "$PROFILE_FILE"
    cat <<EOF > "$PROFILE_FILE"
xdg-user-dirs-update
if uwsm check may-start && uwsm select; then
  exec uwsm start default
fi
EOF
    chown "$USERNAME":"$USERNAME" "$PROFILE_FILE"
else
    echo " $PROFILE_FILE already exists"
    echo "  there is nothing to do"
fi

echo -e "\nAdd: Basic fonts"
pacman --needed --noconfirm -S ttf-opensans 
fc-cache

echo -e "\nReboot system? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    systemctl reboot
else
    echo "Exiting without reboot..."
fi

