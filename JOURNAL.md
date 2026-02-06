# Journal

## 2026-02-06 — DMS “missing display” under niri

### Question

Why does `dms run --session` work under Hyprland but fail under niri with a “missing display” style error?

### Findings

- In the niri session, the Wayland environment is present in both the shell and systemd user manager (`WAYLAND_DISPLAY=wayland-1`, `XDG_RUNTIME_DIR=/run/user/1000`, `XDG_SESSION_TYPE=wayland`).
- The failure is reproducible by running `dms run --session`; the spawned `quickshell` exits with a GTK error:
  - `Gtk-WARNING **: cannot open display:`
- The niri session has no Xwayland (`DISPLAY` unset; `Xwayland` not running).
- `QT_QPA_PLATFORMTHEME=gtk2` and `QT_STYLE_OVERRIDE=adwaita-dark` are exported by Home Manager session vars (generated from our Qt config in `home/theme.nix`).
- `QT_QPA_PLATFORMTHEME=gtk2` is set in-session. When unsetting it just for DMS (`env -u QT_QPA_PLATFORMTHEME dms run --session`), DMS starts successfully under niri.

### Working hypothesis

DMS/Quickshell (Qt6) is picking up `QT_QPA_PLATFORMTHEME=gtk2`, which pulls in GTK2/X11-dependent theme integration. With no Xwayland (no `DISPLAY`) under niri, that theme plugin fails and aborts the UI process.

### Candidate resolutions (semantics to choose)

1. Provide X11 in niri by installing `xwayland-satellite` (niri integrates with it automatically and exports `DISPLAY`).
2. Switch the global Qt platform theme away from `gtk2` to a Wayland-safe option (e.g. GNOME platform theme), so Qt apps don’t depend on an X11 display.
3. Keep the global theme as-is, but spawn DMS with `QT_QPA_PLATFORMTHEME` unset (targeted workaround).

### Decision

- Prefer Wayland-safe: switch Home Manager Qt platform theme from `gtk` (→ `gtk2`) to `adwaita`.

### Next checks

- Confirm where `QT_QPA_PLATFORMTHEME=gtk2` is coming from in HM/NixOS settings.
- Evaluate whether `qgnomeplatform` (or another platform theme) is available and works cleanly under both niri and hypr.
- If we choose Xwayland: verify niri logs show `listening on X11 socket: :0` after adding xwayland-satellite.
