# Architecture: Layering Model

*Captured 2026-02-05 after debugging the OpenURI portal mess*

## Core Insight

**"Portable" is mostly a myth.** The only truly portable things are:
- Shell dotfiles (`.zshrc`, `.gitconfig`) 
- Editor config (`.config/nvim/`) *if* self-managing (LazyVim)
- Identity (SSH keys, GPG keys)

Everything else is either NixOS-specific or lives in devcontainers.

## Natural Clusters

| Cluster | Scope | Update Cadence | Examples |
|---------|-------|----------------|----------|
| **1. Machine Identity** | Per-host, never shared | Once (at install) | disko, hardware-configuration, hostId, hostname |
| **2. Firmware** | NixOS, shared across *your* machines | Yearly/Stable | Kernel, ZFS, LUKS, drivers, NVIDIA, boot |
| **3. System Services** | NixOS, shared | Yearly | Docker, libvirt, networking, printing, pipewire, bluetooth |
| **4. Desktop Session** | NixOS workstations only | Yearly | Compositor, portals, polkit, secrets, greetd, session env vars |
| **5. Desktop Shell** | NixOS workstations, user-flavored | Yearly | Panel (DMS), terminal (foot), launcher, file manager |
| **6. User Taste** | Home-manager, NixOS-only | Yearly | Keybinds, colors, shell prompt, editor config |
| **7. Rolling Edge** | Flatpak or devcontainer | Continuous | VS Code, language servers, cargo/npm/nuget |

### Key Observations

- **Cluster 2+3+4 = "The Desktop OS"** - What Windows/macOS ship. 90% of installed software. Frozen and boring.
- **Cluster 7 is tiny** - VS Code and devcontainers. That's it.
- **Cluster 6 is deceptively small** - Keybinds, theme, prompt. Not "apps".
- **home-manager is misnamed** - It's "user preferences for *this* NixOS desktop", not portable dotfiles.

## Proposed Directory Structure

```
hosts/
  zbook/
    default.nix          # Imports from modules, sets machine identity
    hardware.nix         # Generated, machine-specific
    disks.nix            # Disko, machine-specific

modules/
  firmware/              # Cluster 2: Kernel, ZFS, LUKS, drivers
    boot.nix
    zfs.nix
    nvidia.nix
    
  services/              # Cluster 3: Daemons
    virtualization.nix   # docker, libvirt
    networking.nix
    printing.nix
    sound.nix            # pipewire
    snapshots.nix        # sanoid
    
  session/               # Cluster 4: Desktop session plumbing
    wayland.nix          # portals, polkit, secrets, env vars (the "trait")
    niri.nix             # compositor binding (trait impl)
    hyprland.nix
    
  desktop/               # Cluster 5: Shell/apps (or merge into session?)
    shell.nix            # panel, launcher, notifications
    apps.nix             # foot, file manager, etc.

home/                    # Cluster 6: User taste (NixOS-only!)
  shell.nix              # zsh config, prompt
  editor.nix             # neovim
  keybinds.nix           # compositor keybinds
  theme.nix              # colors, fonts

# Cluster 7 lives outside:
# - Flatpak (VS Code, browsers)
# - devcontainer.json (per-project)
```

## The "Should This Exist?" Test

Before adding anything:

1. **Would I want this on WSL?** → No? NixOS-specific → `modules/`
2. **Would I want this on a headless server?** → No? Desktop → `session/` or `desktop/`
3. **Does it need hardware?** → Yes? → `firmware/`
4. **Does it run as a daemon?** → Yes? → `services/`
5. **Is it user preference?** → Yes? → `home/` (still NixOS-only!)
6. **Do I need latest version weekly?** → Yes? → Flatpak or devcontainer

## Lessons Learned

### Portal Debugging (2026-02-05)

**Root cause**: Home-manager's hyprland module auto-enables `xdg.portal`, which sets `NIX_XDG_DESKTOP_PORTAL_DIR` to user profile. But portal packages were at system level. Portal daemon couldn't find any `.portal` files.

**Fix**: `wayland.windowManager.hyprland.portalPackage = null` in home-manager config.

**Lesson**: NixOS and home-manager don't coordinate on who owns what. Pick one to manage portals.

### OpenURI Implementation

OpenURI is **built into xdg-desktop-portal itself** (uses GLib's `g_app_info_get_default_for_uri_scheme`). No backend portal implements it. But if the portal can't find *any* backends, it doesn't expose the interface at all.

The `.portal` files (gtk.portal, kde.portal, gnome.portal) declare which `impl.portal.*` interfaces each backend provides. None of them list OpenURI - it's handled by the main portal using GLib app info plus the AppChooser backend for dialogs.

## Status

- [x] Layering model documented
- [ ] Refactor directory structure to match (deferred - works fine as-is)
- [x] Session module skeleton (`modules/session/wayland.nix`)
- [x] Portal bug fixed
- [ ] Clean up session module, remove nixpkgs duplication
