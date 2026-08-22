#!/usr/bin/env bash
# post-setup/post-setup.sh - re-apply local customizations after an illogical-impulse install.
# Idempotent. Safe to re-run.
#
# Usage: post-setup/post-setup.sh [PATH_TO_illogical-impulse-backup-dir]
#   Pass a ~/.config-backup-illogical-impulse-* dir to also restore Kvantum themes.
#
# Layout:
#   post-setup/
#     post-setup.sh        <- this orchestrator
#     common.sh            <- shared helpers (die, backup-dir arg)
#     modules/
#       01-hypr-env.sh     <- hypridle/hyprland env tweaks
#       02-hypr-scripts.sh <- recreate the 4 scripts the installer deletes
#       03-default-apps.sh <- custom/variables.lua default-app overrides
#       04-fish.sh         <- fish config + variables personalizations
#       05-kvantum.sh      <- NeoWin theme restore (from backup dir)
#     hypr-scripts/        <- the 4 script files, copied verbatim
#     assets/              <- custom/variables.lua source

set -euo pipefail
source "$(dirname "$0")/common.sh"

run_module modules/01-hypr-env.sh
run_module modules/02-hypr-scripts.sh
run_module modules/03-default-apps.sh
run_module modules/04-fish.sh
run_module modules/05-kvantum.sh

echo "post-setup: re-apply done. Run 'hyprctl reload' (and restart fish) to activate."
