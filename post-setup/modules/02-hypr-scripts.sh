#!/usr/bin/env bash
# 02-hypr-scripts.sh - recreate the 4 hyprland scripts the installer deletes via --delete rsync.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

mkdir -p "$SCRIPTS_DIR"
for s in fake-sleep.sh fake-sleep-ssh.sh workspace_action.sh zoom.sh; do
  install_hypr_script "$s"
done
