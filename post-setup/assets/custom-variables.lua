-- Custom overrides (re-applied after illogical-impulse install)
-- Loaded after hyprland/variables.lua defaults, so these win.

terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'ghostty' 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'thunar' 'dolphin' 'nautilus' 'nemo' 'kitty -1 fish -c yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zen-browser' 'google-chrome-stable' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'codium' 'windsurf' 'antigravity' 'code' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'libreoffice' 'wps' 'onlyoffice-desktopeditors'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'subl' 'kate' 'gnome-text-editor' 'emacs'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'missioncenter' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"
