# Firmware OS Project

## Mission

Build a "Firmware OS" - a NixOS-based system that inverts the traditional Linux distro philosophy. The core insight: Windows/macOS get one thing right that Linux gets wrong - stable frozen OS with rolling apps. 

**Three-layer architecture:**
1. **Firmware** (NixOS 25.11 stable, minimal): Wayland, drivers, ZFS, libvirt, docker, encryption. Tuned once, never think about again.
2. **Rolling Apps**: VS Code, Neovim, browsers. Via nixpkgs-unstable overlay or Flatpak for GUI apps wanting FHS.
3. **Dev Environments**: devcontainer.json - portable across Win11/WSL, Codespaces, and Firmware OS. Use native package managers (cargo/npm/nuget), NOT nix.

Philosophy: "GNU/Linux except Linux" - make the kernel and drivers disappear like NT does with WSL.

Key invariant: ZFS snapshots as first-class rollback for *everything* (system state + uncommitted work), not just nix generations.

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

Reliability constraint: avoid long-running cache builds inside MCP tool calls (client timeouts, process-group SIGINT). MCP tools *assert caches exist* and, if missing, return `status=missing_cache` with an explicit synchronous build command (`tools/nixos-mcp/scripts/build-caches.mjs --all`) to run, then retry.

Ergonomics: cached option JSON files are rewritten to multiline (jq pretty-print) so they're not single ~10MB lines in editors; MCP parsing is unchanged.

User preference: keep cache artifacts editor/rg-friendly (avoid single-line mega-JSON).

Maintenance note: the MCP server implementation uses the SDK's high-level `McpServer.registerTool` API (the lower-level `Server` is deprecated).

Validation: confirmed via stdio client that `listTools` works and each tool returns structured JSON (e.g. `ok` for built caches and `missing_cache` for absent caches).

Philosophy: Give the AI real tools instead of making it hallucinate option names.

### Keyboard layout consistency

**Problem discovered**: LUKS prompt + emergency shell used inconsistent keymaps (Colemak vs Colemak-DH, ANSI vs ISO), causing passphrase/user password confusion.

**Decision**: Use XKB as the single source of truth (ISO UK + `mod_dh_iso_uk`), and set `console.useXkbConfig = true` so TTY derives its keymap from XKB. Home-manager no longer sets `XKB_DEFAULT_*` env vars; Hyprland input config is derived from system XKB via `osConfig`.
