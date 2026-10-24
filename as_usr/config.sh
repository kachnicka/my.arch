#!/bin/bash

SCRIPT_PATH="$(dirname "$(realpath "$0")")"
mkdir -p "$HOME/.config/uwsm/env.d"

pushd "$SCRIPT_PATH"/../dotfiles
stow -t ~ -R */
popd
