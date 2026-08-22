#!/bin/bash
# ~/.config/hypr/hyprland/scripts/fake-sleep.sh

export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/)

if hyprctl monitors -j | jq -e '.[0].dpmsStatus == true' > /dev/null; then
  hyprctl eval 'hl.config({ misc = { mouse_move_enables_dpms = false, key_press_enables_dpms = false } })'
  sleep 0.5
  hyprctl dispatch dpms off
else
  hyprctl eval 'hl.config({ misc = { mouse_move_enables_dpms = true, key_press_enables_dpms = true } })'
fi
