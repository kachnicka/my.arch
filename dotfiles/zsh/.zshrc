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
