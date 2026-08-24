#!/usr/bin/env bash
# common.sh - shared helpers for post-setup modules.
# Sourced by post-setup.sh (never run directly).

# Resolve repo root (the post-setup/ dir)
POST_SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$POST_SETUP_DIR")"

# Where your live config lives
HYPR="$HOME/.config/hypr"
SCRIPTS_DIR="$HYPR/hyprland/scripts"
FISHRC="$HOME/.config/fish/config.fish"
FISHVARS="$HOME/.config/fish/fish_variables"

# Optional backup dir passed as $1 to post-setup.sh
BACKUP_DIR="${1:-}"

# Run a module script, aborting the whole run on failure.
run_module() {
  local mod="$1"
  local path="$POST_SETUP_DIR/$mod"
  [ -f "$path" ] || { echo "post-setup: missing module $path" >&2; return 1; }
  echo "==> post-setup: $mod"
  bash "$path"
}

# Copy a tracked script asset into the live hypr scripts dir, mark executable.
install_hypr_script() {
  local name="$1"
  local src="$POST_SETUP_DIR/hypr-scripts/$name"
  [ -f "$src" ] || { echo "post-setup: missing asset $src" >&2; return 1; }
  mkdir -p "$SCRIPTS_DIR"
  install -m 755 "$src" "$SCRIPTS_DIR/$name"
}

# Copy a tracked fish function into ~/.config/fish/functions/.
install_fish_function() {
  local name="$1"                          # e.g. shd.fish
  local src="$POST_SETUP_DIR/fish-functions/$name"
  [ -f "$src" ] || { echo "post-setup: missing fish function $src" >&2; return 1; }
  mkdir -p "$HOME/.config/fish/functions"
  install -m 644 "$src" "$HOME/.config/fish/functions/$name"
}
