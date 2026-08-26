#!/bin/bash

# arch install:
#     NetworkManager
#     GRUB

PACMAN="pacman --needed --noconfirm"

# expected to run as root right after installation
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# validate args up front so we fail fast before making any system changes
USERNAME="$1"
if [ -z "$USERNAME" ]; then
    echo " Error: username argument is required" >&2
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
$PACMAN -Syu
$PACMAN -S man-db man-pages

echo -e "\nEnable: paccache timer"
$PACMAN -S pacman-contrib
systemctl enable paccache.timer

echo -e "\nUpdate: pacman mirrorlist"
$PACMAN -S rate-mirrors
rate-mirrors --allow-root arch > /etc/pacman.d/mirrorlist

echo -e "\nEnable: NetworkManager"
systemctl enable NetworkManager

echo -e "\nAdd: nftables firewall"
$PACMAN -S nftables
NFT_CONF="/etc/nftables.conf"
cat <<'NFT_EOF' > "$NFT_CONF"
#!/usr/bin/nft -f

flush ruleset

table inet filter {
	chain input {
		type filter hook input priority 0; policy drop;

		ct state established,related accept
		iif "lo" accept

		# SSH
		tcp dport 22 accept

		# web server
		tcp dport { 80, 443 } accept

		icmp type echo-request accept
		ip6 nexthdr icmpv6 icmpv6 type { echo-request, nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}

	chain output {
		type filter hook output priority 0; policy accept;
	}
}
NFT_EOF
if nft -c -f "$NFT_CONF" 2>/dev/null; then
	systemctl enable nftables
else
	echo " Warning: nftables syntax check skipped (nf_tables may not be loaded yet)"
	systemctl enable nftables
fi

echo -e "\nAdd: SSH server"
$PACMAN -S openssh
# generate host keys so sshd -t does not fail on fresh install ("no hostkeys available")
ssh-keygen -A
SSHD_DROPIN="/etc/ssh/sshd_config.d/50-custom.conf"
mkdir -p /etc/ssh/sshd_config.d
cat <<'EOF' > "$SSHD_DROPIN"
PermitRootLogin no
PasswordAuthentication yes
EOF
if sshd -t 2>/dev/null; then
	systemctl enable sshd
else
	echo " Error: sshd_config syntax check failed" >&2
	rm -f "$SSHD_DROPIN"
	exit 1
fi

echo -e "\nEnable: fstrim.timer"
systemctl enable fstrim.timer

echo -e "\nEdit: /etc/sudoers"
$PACMAN -S sudo
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
    echo " adding deny = 5"
    sed -i '/^# deny = 3$/ s/# deny = 3/deny = 5/' "$FAILLOCK_FILE"
else
    echo " there is nothing to do"
fi

#

echo -e "\nAdd: user '$USERNAME'"
$PACMAN -S zsh 
if id "$USERNAME" &>/dev/null; then
    echo " there is nothing to do"
else
    useradd -m -G wheel,games -s /bin/zsh "$USERNAME"
    passwd "$USERNAME"
    echo " added '$USERNAME'"
fi

echo -e "\nAdd: CPU microcode"
if grep -qi "GenuineIntel" /proc/cpuinfo; then
    echo " detected: Intel"
    $PACMAN -S intel-ucode
elif grep -qi "AuthenticAMD" /proc/cpuinfo; then
    echo " detected: AMD"
    $PACMAN -S amd-ucode
fi

echo -e "\nAdd: GPU driver"
GPU_INFO=$(lspci | grep -E "VGA|3D")
if echo "$GPU_INFO" | grep -Eqi "AMD|Advanced Micro Devices"; then
    echo " detected: AMD"
    $PACMAN -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
elif echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    echo " detected: NVIDIA"

    # kernel variant: prebuilt nvidia-open for 'linux', dkms + headers otherwise
    if pacman -Qq linux &>/dev/null; then
        NVIDIA_KMOD="nvidia-open"
        NVIDIA_HEADERS=""
    else
        NVIDIA_KMOD="nvidia-open-dkms"
        NVIDIA_HEADERS=""
        if pacman -Qq linux-lts &>/dev/null; then
            NVIDIA_HEADERS="linux-lts-headers"
        elif pacman -Qq linux-zen &>/dev/null; then
            NVIDIA_HEADERS="linux-zen-headers"
        else
            # any other kernel: match headers to installed kernel package
            OTHER_KERNEL=$(pacman -Qq | grep -E '^linux(-|$)' | head -1)
            if [ -n "$OTHER_KERNEL" ]; then
                NVIDIA_HEADERS="${OTHER_KERNEL}-headers"
            fi
        fi
    fi

    # GPU generation: nvidia-open requires GSP firmware (Turing+);
    # pre-Turing (GTX 10xx and older) unsupported since 590 mainline (Dec 2025)
    NVIDIA_MODEL=$(lspci | grep -iE "VGA|3D" | grep -i "NVIDIA" | head -1)
    if echo "$NVIDIA_MODEL" | grep -qiE "RTX|GTX 16"; then
        $PACMAN -S $NVIDIA_KMOD $NVIDIA_HEADERS nvidia-utils lib32-nvidia-utils \
                    nvidia-settings egl-wayland libva-nvidia-driver

        # kernel cmdline (modprobe.d loads too late to suppress simpledrm)
        # check each param independently so a present modeset does not skip preserve flag
        for param in nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1; do
            if ! grep -q "$param" /etc/default/grub; then
                echo " adding $param to GRUB_CMDLINE_LINUX_DEFAULT"
                sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\([^\"]*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $param\"/" /etc/default/grub
            fi
        done

        # early KMS
        if ! grep -qE "^MODULES=.*nvidia_drm" /etc/mkinitcpio.conf; then
            echo " adding nvidia modules to mkinitcpio MODULES"
            sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        else
            echo " nvidia modules already in MODULES"
        fi

        # hibernate omitted: early MODULES + VRAM preservation breaks hibernation (ArchWiki)
        systemctl enable nvidia-suspend.service nvidia-resume.service
    else
        # pre-Turing: nvidia-open will not load (black screen), install nouveau fallback
        echo " Warning: Pre-Turing NVIDIA GPU detected ($NVIDIA_MODEL)"
        echo " nvidia-open requires GSP firmware (Turing+). Installing nouveau fallback."
        echo " After setup, install nvidia-580xx-dkms from AUR for proprietary drivers."
        # nouveau kernel module is built into stock 'linux' — only mesa needed for Wayland
        $PACMAN -S mesa lib32-mesa
    fi
elif echo "$GPU_INFO" | grep -qi "Intel"; then
    echo " detected: Intel"
    # intel-media-driver for Broadwell+; use libva-intel-driver for pre-Haswell
    $PACMAN -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
else
    echo " detected: nothing"
    echo " there is nothing to do"
fi

# Rebuild initramfs after GPU drivers so modules are picked up.
mkinitcpio -P

# Regenerate grub.config unconditionally: microcode initrd + kernel params
# must be picked up for all GPU types (AMD/Intel/NVIDIA/none)
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\nAdd: NTP clock sync"
if timedatectl show | grep -q "NTPSynchronized=no"; then
    if ! timedatectl set-ntp true; then
        echo " Failed to enable NTP sync."
        exit 1
    fi
else
    echo " NTP sync is enabled."
fi

echo -e "\nAdd: Audio stack"
$PACMAN -S rtkit
systemctl enable rtkit-daemon.service

echo -e "\nAdd: Bluetooth"
if ls /sys/class/bluetooth/ 2>/dev/null | grep -q "^hci"; then
	echo " detected: bluetooth hardware"
	$PACMAN -S bluez bluez-utils
	systemctl enable bluetooth
else
	echo " detected: nothing"
	echo " there is nothing to do"
fi

echo -e "\nAdd: Power management"
CHASSIS=$(hostnamectl chassis-type 2>/dev/null || echo "unknown")
HAS_BATTERY=$(ls /sys/class/power_supply/ 2>/dev/null | grep -q "^BAT" && echo yes || echo no)
if [ "$CHASSIS" = "laptop" ] || [ "$CHASSIS" = "convertible" ] || [ "$CHASSIS" = "tablet" ] || [ "$HAS_BATTERY" = "yes" ]; then
	echo " detected: $CHASSIS"
	echo "Install power management? (y/N)"
	read -r response
	if [[ "$response" =~ ^[Yy]$ ]]; then
		# AMD laptops: power-profiles-daemon (platform_profile integration).
		# Intel laptops: TLP (aggressive runtime PM) + tlp-pd (PPD D-Bus compat).
		if grep -qi "AuthenticAMD" /proc/cpuinfo; then
			$PACMAN -S power-profiles-daemon
			systemctl enable power-profiles-daemon
		else
			$PACMAN -S tlp tlp-pd
			systemctl enable tlp
		fi
	fi
else
	echo " detected: $CHASSIS"
	echo " there is nothing to do"
fi

echo -e "\nAdd: Hyprland"
# TODO: uwsm for user now, maybe greetd+tuigreet later?
$PACMAN -S hyprland uwsm xdg-user-dirs
# .zprofile intentionally not written here: owned by dotfiles repo
# (dotfiles/zsh/.zprofile handles xdg-user-dirs-update + uwsm start)

echo -e "\nAdd: Basic fonts"
$PACMAN -S ttf-opensans 
fc-cache

echo -e "\nReboot system? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    systemctl reboot
else
    echo "Exiting without reboot..."
fi

