#!/bin/bash

SCRIPT_PATH="$(dirname "$(realpath "$0")")"
pushd "$SCRIPT_PATH"/../dotfiles
stow -t ~ -R */
popd
