#!/usr/bin/env bash
# 04-fish.sh - fish config + variables personalizations (idempotent).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

[ -f "$FISHRC" ] || { echo "post-setup: $FISHRC not found, skipping fish"; exit 0; }

# Append interactive-block customizations only once (guarded by a marker).
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

# Re-add go/bin to universal fish path vars.
if [ -f "$FISHVARS" ] && ! grep -q '^SETUVAR fish_user_paths:/home/pizzav/go/bin' "$FISHVARS"; then
  echo 'SETUVAR fish_user_paths:/home/pizzav/go/bin' >> "$FISHVARS"
fi

# Re-add pure prompt theme block (only if absent).
if [ -f "$FISHVARS" ] && ! grep -q '^SETUVAR pure_' "$FISHVARS"; then
  cat "$POST_SETUP_DIR/assets/fish_pure_vars.txt" >> "$FISHVARS"
fi

# Restore tracked fish functions the installer may have removed from functions/.
for fn in shd.fish nap.fish; do
  install_fish_function "$fn"
done
