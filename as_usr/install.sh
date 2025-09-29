#!/bin/sh

# dev tools
sudo pacman --needed --noconfirm -S base-devel vulkan-devel llvm clang libc++ lld cmake ninja mold git python github-cli
sudo pacman --needed --noconfirm -S renderdoc valgrind

# dev env
sudo pacman --needed --noconfirm -S alacritty tmux neovim npm ripgrep unzip
sudo pacman --needed --noconfirm -S ttf-jetbrains-mono ttf-jetbrains-mono-nerd

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
sudo pacman --needed --noconfirm -S zsh-syntax-highlighting zsh-history-substring-search

# config management
sudo pacman --needed --noconfirm -S stow

# apps
if [ ! -x /bin/yay ]; then
    mkdir -p /tmp/yay
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
    pushd /tmp/yay
    PACMAN="pacman --needed --noconfirm" makepkg -si
    popd
fi
sudo pacman --needed --noconfirm -S htop curl thunderbird vlc vlc-plugins-all udiskie
sudo pacman --needed --noconfirm -S flameshot grim slurp wl-clipboard wl-clip-persist
yay --needed --noconfirm -S brave-bin

# audio
sudo pacman --needed --noconfirm -S pipewire wireplumber playerctl
sudo pacman --needed --noconfirm -S pipewire-pulse pipewire-alsa pipewire-audio
sudo pacman --needed --noconfirm -S pavucontrol
systemctl --user enable pipewire pipewire-pulse wireplumber
# sudo pacman --needed --noconfirm -S pipewire-jack
# sudo pacman --needed --noconfirm -S libcamera
# as_root:
# sudo pacman --needed --noconfirm -S bluez bluez-utils pipewire-bluez5
# sudo systemctl enable bluetooth

# hyprland
sudo pacman --needed --noconfirm -S hyprpaper hypridle waybar libnotify dunst
sudo pacman --needed --noconfirm -S qt5-wayland qt6-wayland adw-gtk-theme
sudo pacman --needed --noconfirm -S gammastep brightnessctl ddcutil
sudo pacman --needed --noconfirm -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
yay --needed --noconfirm -S tofi

# apps
sudo pacman --needed --noconfirm -S imv gimp
# yay --needed --noconfirm -S tev
