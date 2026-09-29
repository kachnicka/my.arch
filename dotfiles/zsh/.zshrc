HAS_WIDECHARS="false"
if [[ -e $HOME/.config/zsh/manjaro-zsh-config ]]; then
    source $HOME/.config/zsh/manjaro-zsh-config
fi

# Disable auto-correct (manjaro config enables it — annoying "correct to?" prompts)
unsetopt correct

# Fish-like autosuggestions (gray ghost text from history).
# manjaro-zsh-config already provides syntax-highlighting + history-substring-search.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

fpath+=($HOME/.config/zsh/pure)
autoload -U promptinit; promptinit
prompt pure

vitis_env() {
    source /home/kachnicka/dev/amd/2025.2.1/Vitis/settings64.sh
    export PLATFORM_REPO_PATHS=/home/kachnicka/dev/amd/2025.2.1/Vitis/base_platforms
    export SYSROOT=/home/kachnicka/dev/amd/2025.2.1/xilinx-zynqmp-common-v2025.2/sdk/sysroots/cortexa72-cortexa53-amd-linux
    export EDGE_APP_SW=/home/kachnicka/dev/amd/2025.2.1/xilinx-zynqmp-common-v2025.2
    echo "Vitis 2025.2.1 environment ready. Platform: KV260 base"
}

