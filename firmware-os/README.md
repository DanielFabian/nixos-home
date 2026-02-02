# Firmware OS

**GNU/Linux except Linux** - A NixOS-based "firmware layer" that makes hardware disappear, topped with rolling apps and portable dev environments.

## Philosophy

| Layer | Stability | Updates | Examples |
|-------|-----------|---------|----------|
| Firmware | Rock solid | Quarterly | Wayland, drivers, ZFS, Docker, libvirt |
| Apps | Rolling | Weekly | VS Code, Neovim, Firefox, Spotify |
| Dev | Portable | Per-project | devcontainer.json (works on Win/WSL/Codespaces/here) |

## Bootstrap (from NixOS 25.11 installer)

```bash
# 1. Get this repo
nix-shell -p git
git clone https://github.com/youruser/nixos-home /tmp/config
cd /tmp/config/firmware-os

# 2. Verify disk device (adjust disko/zbook.nix if needed)
lsblk

# 3. Partition and mount
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko/zbook.nix

# 4. Generate hardware config
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/zbook/

# 5. Install
sudo nixos-install --flake .#zbook

# 6. Reboot, then enable secure boot (see docs/secure-boot.md)
```

## Post-Install: Secure Boot

```bash
# Generate keys
sudo sbctl create-keys

# Edit configuration.nix to enable lanzaboote
# ... (uncomment the lanzaboote section in modules/firmware/boot.nix)
sudo nixos-rebuild switch --flake .#zbook

# Verify and enroll
sudo sbctl verify
sudo sbctl enroll-keys --microsoft

# Reboot, enable Secure Boot in BIOS
```

## Structure

```
firmware-os/
├── flake.nix              # Entry point
├── disko/                 # Declarative disk layouts
│   └── zbook.nix
├── hosts/                 # Per-machine configs
│   └── zbook/
├── modules/
│   ├── firmware/          # Stable layer (boot, ZFS, drivers, etc)
│   └── desktop/           # Wayland compositor
└── home/                  # User config (home-manager)
```

## Key Decisions

- **ZFS on LUKS** - Battle-tested encryption, excellent snapshots
- **Sanoid** - Automated snapshots (15min/hourly/daily retention)
- **Hyprland** - Modern Wayland compositor, good NVIDIA support
- **LazyVim** - Self-managing neovim config (not Nix-managed plugins)
- **VS Code mutable extensions** - Let the ecosystem be the ecosystem
- **Colemak-DH** - Superior ergonomic layout
- **Foot terminal** - Wayland-native, fast, minimal

## Snapshots

Your uncommitted code is protected by aggressive ZFS snapshots:
- `rpool/safe/home`: every 15 min, kept for 3 hours
- Can always rollback: `sudo zfs rollback rpool/safe/home@<snapshot>`

List snapshots: `zfs list -t snapshot`
