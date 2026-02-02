# Firmware OS Project

## Mission

Build a "Firmware OS" - a NixOS-based system that inverts the traditional Linux distro philosophy. The core insight: Windows/macOS get one thing right that Linux gets wrong - stable frozen OS with rolling apps. 

**Three-layer architecture:**
1. **Firmware** (NixOS 25.11 stable, minimal): Wayland, drivers, ZFS, libvirt, docker, encryption. Tuned once, never think about again.
2. **Rolling Apps**: VS Code, Neovim, browsers. Via nixpkgs-unstable overlay or Flatpak for GUI apps wanting FHS.
3. **Dev Environments**: devcontainer.json - portable across Win11/WSL, Codespaces, and Firmware OS. Use native package managers (cargo/npm/nuget), NOT nix.

Philosophy: "GNU/Linux except Linux" - make the kernel and drivers disappear like NT does with WSL.

Key invariant: ZFS snapshots as first-class rollback for *everything* (system state + uncommitted work), not just nix generations.

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

**User preferences**:
- Colemak-DH layout
- Caps → Escape (vim life)
- Zsh with vi mode + starship
- Foot terminal (Wayland-native)
- LazyVim (self-managing, not Nix-managed plugins)
- VS Code with mutable extensions

**Hyprland keybinds**: Using vim-style navigation mapped to Colemak-DH physical positions (mnei instead of hjkl).

**Next steps**:
1. Boot ZBook with NixOS installer
2. Verify disk device name (`lsblk`)
3. Run disko
4. Verify NVIDIA bus IDs (`lspci | grep -i nvidia`)
5. Install and iterate

**Open questions**:
- Wallpaper rotation setup? (old config had feh timer)
- TrueNAS syncoid target configuration
