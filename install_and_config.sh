#!/bin/sh

SCRIPT_PATH="$(dirname "$(realpath "$0")")"
"$SCRIPT_PATH"/as_usr/install.sh
"$SCRIPT_PATH"/as_usr/config.sh
