# Sourced by login shells only (TTY, graphical session start).
xdg-user-dirs-update
if uwsm check may-start; then
  exec uwsm start hyprland-uwsm.desktop
fi
