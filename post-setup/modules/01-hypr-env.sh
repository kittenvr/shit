#!/usr/bin/env bash
# 01-hypr-env.sh - hypridle + hyprland env tweaks (idempotent).
# Only touches legacy .conf files if they exist; safe on both old and new installs.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# Hypridle: strip the idle listener block (legacy DPMS toggle).
[ -f "$HYPR/hypridle.conf" ] && sed -i '/^listener {/,/^}/d' "$HYPR/hypridle.conf"

# Terminal in hyprland env (legacy .conf).
[ -f "$HYPR/hyprland/env.conf" ] && sed -i 's/env = TERMINAL,.*/env = TERMINAL,ghostty/' "$HYPR/hyprland/env.conf"

# Legacy keybinds.conf ordering (harmless if file doesn't exist).
if [ -f "$HYPR/hyprland/keybinds.conf" ]; then
  sed -i '/launch_first_available.sh.*File manager/s/"dolphin"/"thunar" &/' "$HYPR/hyprland/keybinds.conf"
  sed -i '/launch_first_available.sh.*Browser/s/"google-chrome-stable" //' "$HYPR/hyprland/keybinds.conf"
  sed -i '/launch_first_available.sh.*Task manager/s/"gnome-system-monitor"/"missioncenter" &/' "$HYPR/hyprland/keybinds.conf"
fi

# Starship accent: replace all grey powerline colors with orange accent.
# Covers: bg of pill interiors (bg:252/bg:255), fill dash (fg:245),
# and pill bracket/pipe foregrounds (fg:252/fg:255).
[ -f ~/.config/starship.toml ] && sed -i \
  -e 's/fg:245/fg:#FFAF00/g' \
  -e 's/bg:252/bg:#FFAF00/g' \
  -e 's/bg:255/bg:#FFAF00/g' \
  -e 's/fg:252/fg:#FFAF00/g' \
  -e 's/fg:255/fg:#FFAF00/g' \
  ~/.config/starship.toml
