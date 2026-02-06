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

## 2026-02-06 — MCP server bootstrap

### Goal

Get `tools/nixos-mcp/` runnable so the AI can query real NixOS/Home-Manager options (no guessing).

### Findings

- Node/npm were missing on the host; MCP `package.json` requires Node `>=20`.

### Changes

- Added Node via Home Manager (`pkgs.unstable.nodejs_22`).
- Ran `npm --prefix tools/nixos-mcp ci` and built caches with `npm --prefix tools/nixos-mcp run -s build-caches`.

### Result

- `npm --prefix tools/nixos-mcp run -s smoke` now returns `status=ok` results for stable/unstable package queries.

## 2026-02-06 — Hyprland crashes when launched from greeter

### Question

Why does Hyprland “crash during opening” when selected in the greeter, while niri works fine?

### Findings

- The failure is a real coredump (SIGSEGV), not just Hyprland exiting back to the greeter.
- `coredumpctl info` for the latest crash shows a segfault in Hyprland’s internal `eglLog` during EGL teardown:
  - `eglDestroyContext` → Aquamarine `CDRMRenderer` destructor → `libEGL_mesa` debug/error report → Hyprland `eglLog` → SEGV.
- Device topology:
  - NVIDIA GPU is `/dev/dri/card0` (pci 01:00.0)
  - Intel GPU is `/dev/dri/card1` (pci 00:02.0)
  - udev tags both as `master-of-seat`, which makes “pick first master device” heuristics ambiguous.
- Niri’s journal logs explicitly show it uses `/dev/dri/card1` as the primary DRM node and works.
- System session variables include `GBM_BACKEND=nvidia-drm` and `__GLX_VENDOR_LIBRARY_NAME=nvidia`.

Additional (post-reboot) finding:

- COSMIC greeter logs show it fails to read all `wayland-sessions` directories, including `/run/current-system/sw/share/wayland-sessions`.
- Confirmed: the system profile currently has no `share/wayland-sessions` directory at all, even though Hyprland’s package contains session files.
- Implication: the greeter may not be launching Hyprland at all (or is launching via a fallback), so “Hyprland crash in greeter” needs a clean reproduction after sessions are correctly installed.

### Working hypothesis

Hyprland/Aquamarine is selecting NVIDIA `/dev/dri/card0` (because it is `master-of-seat` and enumerated first), then failing EGL/DRM setup in a way that triggers an early exit; a cleanup path in Aquamarine’s EGL teardown triggers a Hyprland segfault.

### Candidate resolutions (semantics to choose)

1. Make Intel the only `master-of-seat` DRM device (e.g., udev rule removing that tag from NVIDIA), so Hyprland reliably selects the Intel KMS device.
2. Re-scope NVIDIA-specific env vars (`GBM_BACKEND`, `__GLX_VENDOR_LIBRARY_NAME`) so they only apply to offloaded apps, not to the compositor.
3. Disable NVIDIA KMS/modesetting in PRIME-offload mode if it’s not needed for the intended setup, to reduce “display GPU ambiguity”.

### Decision

- Picked option (2): stop exporting NVIDIA-specific `GBM_BACKEND`/`__GLX_VENDOR_LIBRARY_NAME` globally; keep NVIDIA opt-in for apps via an explicit wrapper.

### Change

- Updated [modules/firmware/nvidia.nix](modules/firmware/nvidia.nix) to remove the global session variables and add `nvidia-offload-wayland`.

### Next step

- Ensure the greeter can enumerate sessions by setting `services.displayManager.sessionPackages` (e.g. `pkgs.niri` and `config.programs.hyprland.package`) and then re-test Hyprland from the greeter.

### Immediate check

- On the current running system, `/run/current-system/sw/share/wayland-sessions` is still missing. This is expected until the new config is actually activated (via `nixos-rebuild switch`) or if COSMIC greeter is ignoring `services.displayManager.sessionPackages`.
- After switching, verify with `ls -la /run/current-system/sw/share/wayland-sessions`.

### New finding

- Even after ensuring the session packages are in the system closure, NixOS may not link `share/wayland-sessions` into `/run/current-system/sw/share` unless that subdir is explicitly included in `environment.pathsToLink`.
- Verified on-host: both `/run/current-system/sw/bin/niri` and `/run/current-system/sw/bin/Hyprland` resolve to store paths that contain `share/wayland-sessions/*.desktop`, yet `/run/current-system/sw/share/wayland-sessions` is absent.

### Fix

- Add `"/share/wayland-sessions"` (and `"/share/xsessions"`) to `environment.pathsToLink` so COSMIC greeter can enumerate sessions from `/run/current-system/sw/share/wayland-sessions`.

### Next blocker (Hyprland still doesn’t launch)

- Even with sessions enumerating, selecting Hyprland returns to the greeter with no new Hyprland coredump on that boot.
- Inspection of Hyprland’s `/share/wayland-sessions/hyprland.desktop` shows it launches `.../bin/start-hyprland` (not `Hyprland` directly).
- `start-hyprland` contains strings like “Hyprland was compiled with Nix - will use nixGL” and calls `execvp`; under greetd’s restricted PATH it plausibly fails to find `nixGL` and exits immediately.

### Fix attempt

- Provide a custom `hyprland.desktop` (as a tiny session package) whose `Exec` points directly to `${config.programs.hyprland.package}/bin/Hyprland`, and use that in `services.displayManager.sessionPackages` to avoid the `start-hyprland` wrapper.

### Build fix

- NixOS requires any package used in `services.displayManager.sessionPackages` to declare `passthru.providedSessions = [ "<session-name>" ]`.
- Added `passthru.providedSessions = [ "hyprland" ]` to the custom session derivation so `nixos-rebuild build` succeeds.

### Refinement

- Overriding `hyprland.desktop` by path is fragile because Hyprland’s own package also provides that filename; the system profile can end up linking the upstream one anyway.
- Switched to a distinct session entry `hyprland-direct.desktop` (session name `hyprland-direct`) so there’s no collision; the greeter will show an explicit “Hyprland (direct)” option.

Additional correction:

- `services.displayManager.sessionPackages` does _not_ directly populate `/run/current-system/sw/share/wayland-sessions`. It builds a separate “desktops” derivation and (for DMs) adds it to `XDG_DATA_DIRS`.
- COSMIC greeter appears to scan `/run/current-system/sw/share/wayland-sessions` (plus a fixed list of other directories), so for COSMIC we need the custom session package to be present in the system profile (e.g. via `environment.systemPackages` + `environment.pathsToLink`).

### New observation

- Launching “Hyprland (direct)” from COSMIC greeter closes the greetd session quickly, but does not produce a new Hyprland coredump (`coredumpctl -b | grep -i hyprland` is empty for that boot).
- Next step is instrumentation: run Hyprland through a wrapper that logs stdout/stderr and key env vars to `~/.cache/hyprland/hyprland-direct-<timestamp>.log` so we can see the real early-exit error (DRM/EGL/seat/session).

### Update

- Hyprland successfully starts from COSMIC greeter using the direct wrapper, but prints: “WARNING: Hyprland is being launched without start-hyprland”.
- `start-hyprland` is a Hyprland-provided watchdog binary; it supports `--no-nixgl` on Nix builds.
- Adjusted the greeter session wrapper to run `start-hyprland --no-nixgl --` (keeps stability + removes the warning, and avoids any nixGL dependency).

Note on `nixGL`:

- `nixGL` is a wrapper used to run Nix-built OpenGL/Vulkan apps against the host’s graphics driver stack by injecting the right driver libraries into the environment. `start-hyprland` may try to use it automatically on Nix builds; `--no-nixgl` disables that behavior.

Decision:

- Keep the `hyprland-direct` session wrapper for control + logging; prefer `start-hyprland --no-nixgl --` over making `nixGL` available in the greeter PATH.
