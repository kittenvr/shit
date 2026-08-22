#!/usr/bin/env bash
# 03-default-apps.sh - write custom/variables.lua default-app overrides.
# Lives in custom/ (not hyprland/) so future `./setup install` runs don't clobber it.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

mkdir -p "$HYPR/custom"
cp -f "$POST_SETUP_DIR/assets/custom-variables.lua" "$HYPR/custom/variables.lua"
