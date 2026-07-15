#!/bin/bash

PACMAN="sudo pacman --needed --noconfirm"

# dev tools
$PACMAN -S base-devel vulkan-devel llvm clang libc++ lld cmake ninja mold git python github-cli
$PACMAN -S renderdoc valgrind

# dev env
$PACMAN -S ghostty tmux neovim npm ripgrep unzip opencode
$PACMAN -S noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu
$PACMAN -S ttf-jetbrains-mono ttf-jetbrains-mono-nerd

TMUX_TPM_CONFIG_PATH=~/.config/tmux/plugins/tpm
if [ ! -d "$TMUX_TPM_CONFIG_PATH" ]; then
    mkdir -p "$TMUX_TPM_CONFIG_PATH"
    git clone https://github.com/tmux-plugins/tpm "$TMUX_TPM_CONFIG_PATH"
else
    pushd "$TMUX_TPM_CONFIG_PATH"
    git pull
    popd
fi
~/.config/tmux/plugins/tpm/bin/install_plugins all

ZSH_PURE_CONFIG_PATH=~/.config/zsh/pure
if [ ! -d "$ZSH_PURE_CONFIG_PATH" ]; then
    mkdir -p "$ZSH_PURE_CONFIG_PATH"
    git clone https://github.com/ivan-volnov/pure "$ZSH_PURE_CONFIG_PATH"
else
    pushd "$ZSH_PURE_CONFIG_PATH"
    git pull
    popd
fi
$PACMAN -S zsh-syntax-highlighting zsh-history-substring-search

# config management
$PACMAN -S stow

# apps
# makepkg 7.0+ uses `sudo -k` (drops creds after each op → re-prompt).
# PACMAN_AUTH=(sudo) prevents it; arrays don't export so must be in ~/.makepkg.conf.
MAKEPKG_USER_CONF="$HOME/.makepkg.conf"
touch "$MAKEPKG_USER_CONF"
grep -qE '^[[:space:]]*PACMAN_AUTH=' "$MAKEPKG_USER_CONF" \
  || printf '\nPACMAN_AUTH=(sudo)\n' >> "$MAKEPKG_USER_CONF"
sudo -v
rm -rf /tmp/yay
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
pushd /tmp/yay
makepkg -si --needed --noconfirm
popd
yay -Y --save --removemake --cleanafter
$PACMAN -S htop curl thunderbird vlc vlc-plugins-all udiskie jq
$PACMAN -S grim slurp satty wl-clipboard wl-clip-persist
yay --needed --noconfirm -S brave-bin

# audio
$PACMAN -S pipewire wireplumber playerctl
$PACMAN -S pipewire-pulse pipewire-alsa pipewire-audio
$PACMAN -S pavucontrol
systemctl --user enable pipewire pipewire-pulse wireplumber
# BT audio: built into pipewire-audio (already installed above); no extra package.

# hyprland
$PACMAN -S hyprpaper hypridle waybar libnotify dunst
$PACMAN -S qt5-wayland qt6-wayland adw-gtk-theme
$PACMAN -S gammastep brightnessctl ddcutil
echo "  WARNING: gammastep location hardcoded to Brno in hyprland.lua -- edit for your location."
$PACMAN -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
yay --needed --noconfirm -S tofi

# apps
$PACMAN -S imv gimp
# yay --needed --noconfirm -S tev
