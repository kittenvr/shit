#!/usr/bin/env bash
# 05-kvantum.sh - restore NeoWin Kvantum themes from the backup dir (optional).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumDark" ]]; then
  echo "post-setup: no backup dir given — skipping Kvantum NeoWin restore"
  exit 0
fi

mkdir -p "$HOME/.config/Kvantum"
cp -an "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumDark"  "$HOME/.config/Kvantum"/
cp -an "$BACKUP_DIR/.config/Kvantum/NeoWinKvantumLight" "$HOME/.config/Kvantum"/
echo "post-setup: restored NeoWin Kvantum themes from $BACKUP_DIR"
