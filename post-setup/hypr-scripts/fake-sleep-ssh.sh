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
