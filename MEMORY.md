# Firmware OS Project

## Mission

Build a "Firmware OS" - a NixOS-based system that inverts the traditional Linux distro philosophy. The core insight: Windows/macOS get one thing right that Linux gets wrong - stable frozen OS with rolling apps.

**Three-layer architecture:**

1. **Firmware** (NixOS 25.11 stable, minimal): Wayland, drivers, ZFS, libvirt, docker, encryption. Tuned once, never think about again.
2. **Rolling Apps**: VS Code, Neovim, browsers. Via nixpkgs-unstable overlay or Flatpak for GUI apps wanting FHS.
3. **Dev Environments**: devcontainer.json - portable across Win11/WSL, Codespaces, and Firmware OS. Use native package managers (cargo/npm/nuget), NOT nix.

Philosophy: "GNU/Linux except Linux" - make the kernel and drivers disappear like NT does with WSL.

Key invariant: ZFS snapshots as first-class rollback for _everything_ (system state + uncommitted work), not just nix generations.

**Repo structure**: Hoisted from `firmware-os/` to root (2026-02-02). Legacy configs (XMonad/X11/PulseAudio era) in git history only.

## Active Tasks

### Bootstrap HP ZBook Studio x360 G5

**Hardware**: HP ZBook Studio x360 G5, Quadro P1000 Mobile (Pascal/GP107). Intel+NVIDIA Optimus.

**Status**: Skeleton created. Ready for actual hardware test.

**Stack**:

- ZFS on LUKS (TPM auto-unlock + passphrase fallback after secure boot)
- NixOS 25.11 stable for firmware layer
- Disko for declarative partitioning
- Lanzaboote for secure boot (phase 2)
- Sanoid for snapshots
- Hyprland for Wayland compositor
- Standard `nvidia` driver (Pascal)
- Flatpak for rolling GUI apps (Flathub)
- Docker + libvirt for dev containers and VMs

**User preferences**:

- Colemak-DH layout
- Caps → Escape (vim life)
- Zsh with vi mode + starship
- Foot terminal (Wayland-native)
- LazyVim (self-managing, not Nix-managed plugins)
- VS Code with mutable extensions

**Hyprland keybinds**: Using vim-style navigation mapped to Colemak-DH physical positions (mnei instead of hjkl).

**Desktop stack** (2026-02-05): Working minimal setup:

- greetd → niri-session directly
- `programs.niri` (nixpkgs) handles portals: portal-gnome (screencast), portal-gtk (files)
- OpenURI is built into xdg-desktop-portal itself (no backend implements it!)
- hyprland available as alternative session
- Plasma/Cosmic disabled (not needed for portal infrastructure anymore)

**Greeter update (2026-02-06)**:

- Switched to COSMIC greeter via `services.displayManager.cosmic-greeter.enable = true` in `modules/desktop/greeter.nix`.

**Portal bug FIXED**: Home-manager's hyprland module was overwriting `NIX_XDG_DESKTOP_PORTAL_DIR` to point at user profile (empty). Fix: `portalPackage = null` in home-manager hyprland config.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for layering model discussion.

**Display**: 4K @ 1.5x scale (Hyprland)

**Confirmed hardware**:

- Intel UHD: PCI:0:2:0 ✓
- Quadro P1000: PCI:1:0:0 ✓

**Installation workflow**:

1. Boot ZBook with NixOS installer USB
2. Verify disk device name (`lsblk` - expect `/dev/nvme0n1`)
3. Clone repo, run disko: `sudo nix run github:nix-community/disko -- --mode disko ./disko/zbook.nix`
4. Install: `sudo nixos-install --flake .#zbook`
5. Reboot, enter LUKS passphrase manually first time
6. **TPM2 enrollment** (after first successful boot):
   ```bash
   # Verify TPM exists
   ls /dev/tpm*
   # Enroll TPM2 (PCR 0=firmware, 7=secure boot state)
   sudo systemd-cryptenroll /dev/nvme0n1p3 --tpm2-device=auto --tpm2-pcrs=0+7
   # Test: reboot should auto-unlock
   ```
7. (Phase 2) Secure Boot with Lanzaboote

**Systemd session integration** (2026-02-06 research):

- Hyprland: home-manager module creates `hyprland-session.target` (BindsTo=graphical-session.target). Environment import + target start happen via a single `exec-once` line in hyprland.conf: `dbus-update-activation-environment --systemd <vars> && systemctl --user stop/start hyprland-session.target`. Env vars (DISPLAY, WAYLAND_DISPLAY, HYPRLAND_INSTANCE_SIGNATURE, XDG_CURRENT_DESKTOP) are pushed BEFORE the target starts.
- Niri: NO home-manager WM module exists. Niri ships its own `niri.service` (Type=notify, BindsTo=graphical-session.target, Before=graphical-session.target) and `niri-shutdown.target`. The `niri --session` binary does env import synchronously in Rust (systemctl import-environment + dbus-update-activation-environment for WAYLAND_DISPLAY/DISPLAY/XDG_CURRENT_DESKTOP/XDG_SESSION_TYPE/NIRI_SOCKET) BEFORE calling sd_notify(Ready), which triggers niri.service→active→graphical-session.target.
- `niri-session` script (used by greetd) also does a blanket `systemctl --user import-environment` + `dbus-update-activation-environment --all` before starting niri.service.
- Both compositors guarantee WAYLAND_DISPLAY is in systemd env before graphical-session.target activates. Services WantedBy=graphical-session.target (like DMS) will have WAYLAND_DISPLAY available.
- `wayland.nix` in home-manager only provides `wayland.systemd.target` option (default: graphical-session.target) for other HM services to reference; it doesn't manage the target itself.

**DMS in Niri regression investigation** (2026-02-06):

- User-reported LKG: `2a90da865856928750429dc83ca363030d90c33d`, first known-bad: `4dbd4ca303a84bc1b28e6da36666881733e15931`.
- Symptom: `dms.service` crash loops in Niri with `Failed to create wl_display (No such file or directory)` / Qt Wayland platform init failure.
- Key intent: stop guessing; need systematic instrumentation to determine (a) who/what triggers `dms.service` (target vs D-Bus), (b) what `WAYLAND_DISPLAY` systemd user manager and `dms.service` see at start, and (c) ordering relative to `niri.service` readiness.
- Note: prior “spawn-at-startup env import” attempts were inconclusive; must verify whether they run and whether they modify the systemd user manager env.

Resolution chosen:

- Root cause localized by history inspection: commit `cb36531` removed `spawn-at-startup "dms" "run" "--session"` from `home/niri-config.kdl`, switching DMS startup to a systemd user unit tied to `graphical-session.target`. This introduced a startup ordering/env fragility (DMS could crash early and hit StartLimit, or start before Wayland env is stable).
- Fix: disable DMS systemd autostart and start DMS explicitly from within each compositor session (niri `spawn-at-startup`, Hyprland `exec-once`).

**New confirmed root cause** (2026-02-06):

- In the current niri session, Wayland env is correct (`WAYLAND_DISPLAY`/`XDG_RUNTIME_DIR` present) but `DISPLAY` is unset because Xwayland is not running.
- DMS spawns `quickshell`, which fails with `Gtk-WARNING **: cannot open display:` when `QT_QPA_PLATFORMTHEME=gtk2` is set.
- Validated workaround: `env -u QT_QPA_PLATFORMTHEME dms run --session` starts successfully under niri.
- Likely fix directions: switch Qt platform theme away from `gtk2` (Wayland-safe) or provide X11 via `xwayland-satellite` so `DISPLAY` exists.

**Provenance** (2026-02-06):

- `QT_QPA_PLATFORMTHEME=gtk2` and `QT_STYLE_OVERRIDE=adwaita-dark` are exported by Home Manager’s generated session-vars script (hm-session-vars), originating from `home/theme.nix` (`qt.platformTheme.name = "gtk"`, `qt.style.name = "adwaita-dark"`).

**Semantic decision** (2026-02-06):

- Prefer Wayland-safe theming: switch `qt.platformTheme.name` from `gtk` (maps to `gtk2`) to `adwaita` so Qt apps don’t depend on X11/Xwayland.

**Hyprland crash under greeter (2026-02-06)**:

- Hyprland repeatedly segfaults during greeter-launched startup/shutdown; coredump shows a SEGV in Hyprland’s `eglLog` during `eglDestroyContext`, called from Aquamarine’s `CDRMRenderer` destructor.
- Practical interpretation: Hyprland exits early due to an EGL/DRM failure, then crashes while cleaning up EGL (so the “crash” seen in the greeter is a hard coredump, not a normal compositor exit).
- Strong correlation with hybrid GPU device selection:
  - NVIDIA is `/dev/dri/card0` (pci 01:00.0), Intel is `/dev/dri/card1` (pci 00:02.0).
  - Niri logs show it selects `/dev/dri/card1` as the primary DRM node and works.
  - Both `/dev/dri/card0` and `/dev/dri/card1` are tagged `master-of-seat` by udev, so a compositor that “picks the first master-of-seat” is likely to grab NVIDIA card0.
- Additional likely contributing constraint: system-wide session env sets `GBM_BACKEND=nvidia-drm` and `__GLX_VENDOR_LIBRARY_NAME=nvidia` (in `modules/firmware/nvidia.nix`), while Hyprland’s crash stack shows it is using Mesa EGL (`libEGL_mesa.so.0`) rather than an NVIDIA EGL implementation.
- Current working hypothesis: Hyprland/Aquamarine picks NVIDIA card0, but its Mesa EGL path + global GBM/GLX env leads to EGL errors; Hyprland exits and then hits the Aquamarine EGL teardown segfault.
- Fix direction to validate next: ensure only Intel is treated as the primary/master-of-seat KMS device for the seat, and/or scope NVIDIA-specific env vars to offload-only execution (not globally for the compositor).

**Hyprland from COSMIC greeter (2026-02-06)**:

- Hyprland now starts successfully from COSMIC greeter.
- Key discovery: COSMIC greeter enumerates sessions from `/run/current-system/sw/share/wayland-sessions` (system profile), so we must ensure the relevant `.desktop` entries are in the system closure and that `/share/wayland-sessions` is linked into the system profile.
- Implementation approach: add a custom `hyprland-direct.desktop` session entry that runs a small wrapper which logs startup output and then launches Hyprland via `start-hyprland --no-nixgl --`.
- Rationale: Hyprland recommends `start-hyprland` (watchdog + proper startup); on Nix builds it may try to use `nixGL`, which is undesirable/unavailable in the greeter environment. `--no-nixgl` keeps it stable.

Quick glossary:

- `nixGL`: a wrapper (from the nixGL project) that runs a program with the host’s GPU driver libraries available (typically by injecting the right GL/Vulkan libs into the runtime environment). It’s most relevant on non-NixOS systems or constrained environments where a Nix-built binary can’t find the system’s GL stack.
- Why it mattered here: Hyprland’s `start-hyprland` can try to exec `nixGL`; under greetd the PATH is minimal, so that exec can fail unless we either provide nixGL in PATH or pass `--no-nixgl`.
- Important: `--no-nixgl` does not mean “no GPU”. It just prevents `start-hyprland` from using an extra wrapper to inject driver libraries; on NixOS the normal (GPU-accelerated) driver stack is already available via the system closure/kernel modules.
- Decision: keep the custom greeter session wrapper (`hyprland-direct`) for explicit control and per-launch logging; do not attempt to make `nixGL` available in the greeter environment.

**Implementation (2026-02-06)**:

- Chose “Option A”: removed global `GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, and `WLR_NO_HARDWARE_CURSORS=1` from `environment.sessionVariables`.
- Added a dedicated `nvidia-offload-wayland` wrapper to opt into those variables only when explicitly launching an app on the dGPU.

**Greeter session enumeration issue (2026-02-06)**:

- COSMIC greeter was unable to read `/run/current-system/sw/share/wayland-sessions` (directory absent), so it likely couldn’t reliably offer/launch Hyprland or niri via `.desktop` session entries.
- Fix: set `services.displayManager.sessionPackages` to include `pkgs.niri` and `config.programs.hyprland.package` so the greeter has session files to enumerate.

Refined understanding:

- Even with those packages present in the system closure (binaries available), `/run/current-system/sw/share/wayland-sessions` can remain missing.
- Root cause: `environment.pathsToLink` does not link `"/share/wayland-sessions"` by default; it must be added explicitly for greeters that scan `/run/current-system/sw/share/wayland-sessions`.

Clarification:

- `services.displayManager.sessionPackages` builds a separate “desktops” derivation (`config.services.displayManager.sessionData.desktops`) and is exposed to some DMs via `XDG_DATA_DIRS`; it does not necessarily place files into `/run/current-system/sw/share/wayland-sessions`.
- Because COSMIC greeter scans `/run/current-system/sw/share/wayland-sessions`, custom sessions must be included in the system profile (e.g. added to `environment.systemPackages`) _and_ the subdir must be linked via `environment.pathsToLink`.

**Hyprland session not starting from greeter (2026-02-06)**:

- The upstream Hyprland `hyprland.desktop` uses `Exec=.../bin/start-hyprland`.
- `start-hyprland` appears to try to exec `nixGL` (string: “Hyprland was compiled with Nix - will use nixGL”) via `execvp`; under greetd/cosmic-greeter the PATH is restricted and likely lacks `nixGL`, so Hyprland can exit immediately without a coredump.
- Workaround: provide a custom session `.desktop` entry that runs `${config.programs.hyprland.package}/bin/Hyprland` directly.

Constraints discovered:

- Any package listed in `services.displayManager.sessionPackages` must set `passthru.providedSessions` or evaluation fails.
- Overriding `hyprland.desktop` by installing the same path is fragile because Hyprland’s package also provides that filename; depending on link order, `/run/current-system/sw/share/wayland-sessions/hyprland.desktop` may still resolve to the upstream `start-hyprland` entry.
- Robust approach: ship a distinct `hyprland-direct.desktop` (session name `hyprland-direct`) and select “Hyprland (direct)” in the greeter.

**Open questions**:

- Wallpaper rotation setup? (old config had feh timer)
- TrueNAS syncoid target configuration

### Dev Environment Tooling

**Devcontainer**: Ubuntu 24.04 + Nix feature, full `nixos-rebuild --dry-run` capability. Includes nil LSP + nixfmt.

**nixpkgs grepping**: `scripts/sync-nixpkgs.sh` shallow-clones nixpkgs for ripgrep searches. Gitignored, not a submodule.

**Submodules decision**: Avoid submodules for nixpkgs/home-manager; use `flake.lock` as the single source of truth for pins. Local clones are optional grepping corpora only.

**MCP Server** (`tools/nixos-mcp/`): HTTP proxy to search.nixos.org Elasticsearch API. Three tools:

- `search_nixos_options` - system options (services, hardware, etc.)
- `search_nixos_packages` - package lookup
- `search_home_manager_options` - home-manager options

Build caches synchronously via `tools/nixos-mcp/scripts/build-caches.mjs --all`.

Rule: Before naming any NixOS/Home-Manager option or package attr, query the MCP tools first (don’t invent option names).

Status (2026-02-02): Upstream endpoints changed — `search.nixos.org/backend` now returns 401 (Basic/Bonsai) and `home-manager-options.extranix.com/api` serves HTML. MCP now uses local `nix` + pinned flake inputs instead.

Local-first direction: nixpkgs already contains generators for the same data we want to search:

- Packages: `nixpkgs/pkgs/top-level/packages-info.nix` emits a big `packages.json` (used by `make-tarball.nix`).
- NixOS options: nixpkgs builds a canonical `options.json` via `nixosOptionsDoc` / `nixos/lib/make-options-doc`.
- Home-Manager options: the extranix site now loads `data/options-<release>.json` (the old `/api` JSON endpoint appears gone), so we can cache that file or build HM options JSON from a pinned HM source.

Implementation note: MCP searches `stable` vs `unstable` directly from flake inputs (`nixpkgs` vs `nixpkgs-unstable`) and reads artifacts under `tools/nixos-mcp/.cache/`. Cache building is external/synchronous; `scripts/sync-home-manager.sh` adds a pinned HM grepping corpus.

Perf constraint: `nix search` per-query is too slow for interactive use; package search uses a locally built index (TSV + `rg`) keyed by the pinned flake input so lookups are millisecond-fast after the one-time build.

Perf observation: first option/HM query is slower due to JSON load/parse; subsequent queries in the same server process are much faster (memoized JSON).

Reliability constraint: avoid long-running cache builds inside MCP tool calls (client timeouts, process-group SIGINT). MCP tools _assert caches exist_ and, if missing, return `status=missing_cache` with an explicit synchronous build command (`tools/nixos-mcp/scripts/build-caches.mjs --all`) to run, then retry.

Ergonomics: cached option JSON files are rewritten to multiline (jq pretty-print) so they're not single ~10MB lines in editors; MCP parsing is unchanged.

User preference: keep cache artifacts editor/rg-friendly (avoid single-line mega-JSON).

Maintenance note: the MCP server implementation uses the SDK's high-level `McpServer.registerTool` API (the lower-level `Server` is deprecated).

Validation: confirmed via stdio client that `listTools` works and each tool returns structured JSON (e.g. `ok` for built caches and `missing_cache` for absent caches).

**MCP runtime constraint (2026-02-06)**:

- `tools/nixos-mcp/` requires Node.js `>=20` (`package.json` engines). Node was missing on the host; installed via Home Manager (`pkgs.unstable.nodejs_22`).
- Dependencies installed with `npm --prefix tools/nixos-mcp ci` and caches built via `npm --prefix tools/nixos-mcp run -s build-caches`.

Philosophy: Give the AI real tools instead of making it hallucinate option names.

### Keyboard layout consistency

**Problem discovered**: LUKS prompt + emergency shell used inconsistent keymaps (Colemak vs Colemak-DH, ANSI vs ISO), causing passphrase/user password confusion.

**Decision**: Use XKB as the single source of truth (ISO UK + `mod_dh_iso_uk`), and set `console.useXkbConfig = true` so TTY derives its keymap from XKB. Home-manager no longer sets `XKB_DEFAULT_*` env vars; Hyprland input config is derived from system XKB via `osConfig`.
