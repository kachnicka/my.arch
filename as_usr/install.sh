#!/bin/bash

PACMAN="sudo pacman --needed --noconfirm"

# dev tools
$PACMAN -S base-devel vulkan-devel llvm clang libc++ lld cmake ninja mold git python github-cli
$PACMAN -S renderdoc valgrind

# dev env
# tree-sitter-cli: nvim-treesitter main branch generates parsers from grammar.js
$PACMAN -S ghostty tmux neovim tree-sitter-cli npm ripgrep unzip opencode
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

# pure prompt: upstream sindresorhus/pure pinned to a version tag.
# ghostty >=1.3 injects OSC 133 marks into multiline PS1; the old
# ivan-volnov/pure fork re-parses PROMPT via a newline sentinel and
# duplicates the preprompt under that injection. Upstream >=1.27 builds
# PROMPT once from psvar and never re-parses it.
ZSH_PURE_CONFIG_PATH=~/.config/zsh/pure
ZSH_PURE_VERSION=v1.28.3
ZSH_PURE_REPO=https://github.com/sindresorhus/pure
if [ ! -d "$ZSH_PURE_CONFIG_PATH" ]; then
    git clone "$ZSH_PURE_REPO" "$ZSH_PURE_CONFIG_PATH"
fi
pushd "$ZSH_PURE_CONFIG_PATH" >/dev/null
# migrate clones that still point at the dead ivan-volnov fork
if [ "$(git remote get-url origin)" != "$ZSH_PURE_REPO" ]; then
    git remote set-url origin "$ZSH_PURE_REPO"
fi
# pin to tag: idempotent, and never does `git pull` (fails on detached HEAD)
git fetch --tags origin
git checkout --force "$ZSH_PURE_VERSION"
popd >/dev/null
$PACMAN -S zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search

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
$PACMAN -S htop curl thunderbird vlc vlc-plugins-all udiskie jq xdg-utils
$PACMAN -S grim slurp satty wl-clipboard wl-clip-persist wtype
yay --needed --noconfirm -S brave-bin

# audio
$PACMAN -S pipewire wireplumber playerctl
$PACMAN -S pipewire-pulse pipewire-alsa pipewire-audio
$PACMAN -S pavucontrol
systemctl --user enable pipewire pipewire-pulse wireplumber
# BT audio: built into pipewire-audio (already installed above); no extra package.

# hyprland
# hyprlock: waybar lock module + hypridle
$PACMAN -S hyprpaper hypridle hyprlock waybar libnotify dunst
$PACMAN -S qt5-wayland qt6-wayland adw-gtk-theme
$PACMAN -S gammastep brightnessctl ddcutil
echo "  WARNING: gammastep location hardcoded to Brno in hyprland.lua -- edit for your location."
$PACMAN -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
yay --needed --noconfirm -S tofi
# voice dictation (PTT binds + wrapper scripts in dotfiles/bin and hyprland.lua)
yay --needed --noconfirm -S handy-bin

# apps
$PACMAN -S imv gimp nm-connection-editor
# yay --needed --noconfirm -S tev
