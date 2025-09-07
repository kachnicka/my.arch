HAS_WIDECHARS="false"
if [[ -e $HOME/.config/zsh/manjaro-zsh-config ]]; then
    source $HOME/.config/zsh/manjaro-zsh-config
fi

fpath+=($HOME/.config/zsh/pure)
autoload -U promptinit; promptinit
prompt pure
