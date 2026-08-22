#!/usr/bin/env bash
set -euo pipefail
# post-setup.sh - re-apply local customizations after an illogical-impulse install.
# Idempotent. Safe to re-run.
# Usage: ./post-setup.sh [PATH_TO_illogical-impulse-backup-dir]
#   Pass a ~/.config-backup-illogical-impulse-* dir to also restore Kvantum themes.

HYPR="$HOME/.config/hypr"
SCRIPTS_DIR="$HYPR/hyprland/scripts"
KI_DIR="$HOME/.config/Kvantum"
FISHRC="$HOME/.config/fish/config.fish"
FISHVARS="$HOME/.config/fish/fish_variables"
BACKUP_DIR="${1:-}"

# ----------------------------------------------------------------------------
# 1. Hyprland idle config: strip listener block
sed -i '/^listener {/,/^}/d' "$HYPR/hypridle.conf"

# 2. Hyprland env: terminal
sed -i 's/env = TERMINAL,.*/env = TERMINAL,ghostty/' "$HYPR/hyprland/env.conf"

# 3. Keybinds.conf (legacy): file manager, browser, task manager ordering
sed -i '/launch_first_available.sh.*File manager/s/"dolphin"/"thunar" &/' "$HYPR/hyprland/keybinds.conf"
sed -i '/launch_first_available.sh.*Browser/s/"google-chrome-stable" //' "$HYPR/hyprland/keybinds.conf"
sed -i '/launch_first_available.sh.*Task manager/s/"gnome-system-monitor"/"missioncenter" &/' "$HYPR/hyprland/keybinds.conf"

# 4. Starship accent
sed -i 's/fg:245/fg:#FFAF00/g; s/bg:252/bg:#FFAF00/g; s/bg:255/bg:#FFAF00/g' ~/.config/starship.toml

# 5. Default apps override (update-proof: lives in custom/variables.lua)
#    Your ordering: ghostty, thunar, zen-browser, codium, libreoffice, subl, missioncenter.
#    Keeps upstream windsurf + workspaceGroupSize intact.
mkdir -p "$HYPR/custom"
cat > "$HYPR/custom/variables.lua" <<'LUAEOF'
-- Custom overrides (re-applied after illogical-impulse install)
-- Loaded after hyprland/variables.lua defaults, so these win.

terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'ghostty' 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'thunar' 'dolphin' 'nautilus' 'nemo' 'kitty -1 fish -c yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zen-browser' 'google-chrome-stable' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'codium' 'windsurf' 'antigravity' 'code' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'libreoffice' 'wps' 'onlyoffice-desktopeditors'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'subl' 'kate' 'gnome-text-editor' 'emacs'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'missioncenter' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"
LUAEOF

# 6. Re-create the 4 hyprland scripts the installer deletes via its --delete rsync
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/fake-sleep.sh" <<'EOF'
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
EOF
chmod +x "$SCRIPTS_DIR/fake-sleep.sh"

cat > "$SCRIPTS_DIR/fake-sleep-ssh.sh" <<'EOF'
#!/bin/bash
# ~/.config/hypr/hyprland/scripts/fake-sleep-ssh.sh
# Toggle monitor DPMS state via Hyprland Lua socket

export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/)
SOCK="/run/user/1000/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket"

# Check current DPMS state
DPMS_ON=$(hyprctl monitors -j | jq -e '.[0].dpmsStatus == true' 2>/dev/null && echo 1 || echo 0)

echo "Current DPMS state: $DPMS_ON (1=on, 0=off)"

if [ "$DPMS_ON" = "1" ]; then
    # Screen is on → turn off
    echo "Turning monitor OFF..."
    python3 -c "
import socket, os
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.settimeout(1)
sock.connect('/run/user/1000/hypr/' + os.environ['HYPRLAND_INSTANCE_SIGNATURE'] + '/.socket.sock')
sock.sendall(b'eval hl.dsp.dpms(false)\n')
try:
    resp = sock.recv(4096)
    print('Response:', resp)
except:
    print('Sent (no response)')
sock.close()
"
else
    # Screen is off → turn on
    echo "Turning monitor ON..."
    python3 -c "
import socket, os
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.settimeout(1)
sock.connect('/run/user/1000/hypr/' + os.environ['HYPRLAND_INSTANCE_SIGNATURE'] + '/.socket.sock')
sock.sendall(b'eval hl.dsp.dpms(true)\n')
try:
    resp = sock.recv(4096)
    print('Response:', resp)
except:
    print('Sent (no response)')
sock.close()
"
fi

echo "---"
hyprctl monitors -j | jq '.[0].dpmsStatus'
EOF
chmod +x "$SCRIPTS_DIR/fake-sleep-ssh.sh"

cat > "$SCRIPTS_DIR/workspace_action.sh" <<'EOF'
#!/usr/bin/env bash
curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
dispatcher="$1"
shift ## The target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ## Is this something like r+1 or -1?
  hyprctl dispatch "${dispatcher}" "$1" ## $1 = workspace id since we shifted earlier.
elif [[ "$1" =~ ^[0-9]+$ ]]; then ## Is this just a number?
  target_workspace=$((((curr_workspace - 1) / 10 ) * 10 + $1))
  hyprctl dispatch "${dispatcher}" "${target_workspace}"
else
  hyprctl dispatch "${dispatcher}" "$1" ## In case the target in a string, required for special workspaces.
  exit 1
fi
EOF
chmod +x "$SCRIPTS_DIR/workspace_action.sh"

cat > "$SCRIPTS_DIR/zoom.sh" <<'EOF'
#!/usr/bin/env bash

# Controls Hyprland's cursor zoom_factor, clamped between 1.0 and 3.0

# Get current zoom level
get_zoom() {
    hyprctl getoption -j cursor:zoom_factor | jq '.float'
}

# Clamp a value between 1.0 and 3.0
clamp() {
    local val="$1"
    awk "BEGIN {
        v = $val;
        if (v < 1.0) v = 1.0;
        if (v > 3.0) v = 3.0;
        print v;
    }"
}

# Set zoom level
set_zoom() {
    local value="$1"
    clamped=$(clamp "$value")
    hyprctl keyword cursor:zoom_factor "$clamped"
}

case "$1" in
    reset)
        set_zoom 1.0
        ;;
    increase)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 increase STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current + $2 }")
        set_zoom "$new"
        ;;
    decrease)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 decrease STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current - $2 }")
        set_zoom "$new"
        ;;
    *)
        echo "Usage: $0 {reset|increase STEP|decrease STEP}"
        exit 1
        ;;
esac
EOF
chmod +x "$SCRIPTS_DIR/zoom.sh"

# 7. Fish config: re-add personalizations (idempotent via marker)
if ! grep -q '# === custom (reapplied' "$FISHRC"; then
  cat >> "$FISHRC" <<'EOF'

    # === custom (reapplied after illogical-impulse install) ===
    function np
        mkdir -p $argv[1] && cd $argv[1]
        openspec init --tools opencode
        cp ~/Documents/Templates/AGENTS.md .
        cp ~/Documents/Templates/AUDIT_STARTER.md .
        opencode
    end
    alias hx='helix'
    set -gx EDITOR helix
    set -gx VISUAL helix

    # Added by LM Studio CLI (lms)
    set -gx PATH $PATH /home/pizzav/.lmstudio/bin
    # End of LM Studio CLI section
EOF
fi

# 8. Fish variables: re-add go/bin path
if ! grep -q '^SETUVAR fish_user_paths:/home/pizzav/go/bin' "$FISHVARS" 2>/dev/null; then
  echo 'SETUVAR fish_user_paths:/home/pizzav/go/bin' >> "$FISHVARS"
fi

# 9. Kvantum neo-win themes (restore from a backup dir if provided)
if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumDark" ]]; then
  mkdir -p "$KI_DIR"
  cp -an "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumDark" "$KI_DIR"/
  cp -an "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumLight" "$KI_DIR"/
  echo "Restored NeoWin Kvantum themes from $BACKUP_DIR"
fi

echo "post-setup: re-apply done. Run 'hyprctl reload' (and restart fish) to activate."
