#!/usr/bin/env bash
# Firmware OS installer — one command to go from NixOS installer to working system.
#
# Usage:
#   sudo ./scripts/install.sh <hostname>
#
# Prerequisites:
#   - Booted into NixOS installer (USB/ISO)
#   - Network connectivity (for flake inputs + VS Code download on first login)
#   - Repo cloned locally
#
# What it does:
#   1. Validates hostname against hosts/
#   2. Partitions + formats disk via Disko
#   3. Generates hardware-configuration.nix for the target
#   4. Installs NixOS from the flake
#   5. Generates secure boot keys (for Lanzaboote)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Validation ---

if [[ $EUID -ne 0 ]]; then
  echo "Error: must run as root (sudo)" >&2
  exit 1
fi

# List valid hosts
valid_hosts=()
for d in "$REPO_DIR"/hosts/*/; do
  name="$(basename "$d")"
  if [[ -f "$d/default.nix" ]]; then
    valid_hosts+=("$name")
  fi
done

if [[ $# -lt 1 ]]; then
  echo "Usage: sudo ./scripts/install.sh <hostname>"
  echo ""
  echo "Available hosts:"
  for h in "${valid_hosts[@]}"; do
    echo "  - $h"
  done
  exit 1
fi

HOST="$1"

# Check host exists
if [[ ! -f "$REPO_DIR/hosts/$HOST/default.nix" ]]; then
  echo "Error: unknown host '$HOST'" >&2
  echo "Available hosts:"
  for h in "${valid_hosts[@]}"; do
    echo "  - $h"
  done
  exit 1
fi

# Check disko config exists
if [[ ! -f "$REPO_DIR/disko/$HOST.nix" ]]; then
  echo "Error: no disko layout found at disko/$HOST.nix" >&2
  exit 1
fi

echo "=== Firmware OS Installer ==="
echo "Host:  $HOST"
echo "Disko: disko/$HOST.nix"
echo ""

# --- Confirm disk operation ---

# Extract device path from disko config for display
DISK_DEVICE=$(grep -oP 'device\s*=\s*"\K[^"]+' "$REPO_DIR/disko/$HOST.nix" | head -1)
echo "Target disk: $DISK_DEVICE"
echo ""
echo "WARNING: This will ERASE ALL DATA on $DISK_DEVICE"
echo ""
read -rp "Type 'yes' to continue: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# --- Step 1: Partition + format via Disko ---

echo ""
echo ">>> Step 1/4: Partitioning and formatting ($DISK_DEVICE)..."
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko "$REPO_DIR/disko/$HOST.nix"

echo "    Disk partitioned and formatted."

# Activate swap immediately — the NixOS installer runs /nix/store in tmpfs,
# which overflows on 8GB RAM machines. Swap gives tmpfs room to spill.
SWAP_PART=$(lsblk -lnp -o NAME,FSTYPE "$DISK_DEVICE" | awk '$2 == "swap" {print $1; exit}')
if [[ -n "$SWAP_PART" ]]; then
  echo "    Activating swap ($SWAP_PART) to prevent installer OOM..."
  swapon "$SWAP_PART"
fi

# --- Step 2: Generate hardware-configuration.nix ---

echo ""
echo ">>> Step 2/4: Generating hardware configuration..."
nixos-generate-config --no-filesystems --root /mnt

# Copy generated config into the repo
cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/hosts/$HOST/hardware-configuration.nix"
echo "    Hardware config written to hosts/$HOST/hardware-configuration.nix"

# --- Step 3: Install NixOS ---

echo ""
echo ">>> Step 3/4: Installing NixOS (this takes a while)..."
nixos-install --flake "$REPO_DIR#$HOST" --no-root-passwd

echo "    NixOS installed."

# --- Step 4: Secure boot keys ---

echo ""
echo ">>> Step 4/4: Generating secure boot keys..."
if command -v sbctl &>/dev/null; then
  if [[ ! -d /mnt/etc/secureboot ]]; then
    # Generate keys into the installed system
    mkdir -p /mnt/etc/secureboot
    sbctl create-keys --export /mnt/etc/secureboot
    echo "    Secure boot keys generated at /etc/secureboot"
    echo "    After reboot, enroll keys: sudo sbctl enroll-keys --microsoft"
  else
    echo "    Secure boot keys already exist, skipping."
  fi
else
  echo "    sbctl not available in installer, skipping key generation."
  echo "    Generate keys after first boot: sudo sbctl create-keys"
fi

# --- Done ---

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "  1. Reboot into the new system"
echo "  2. Log in as your user"
echo "  3. (Optional) Enroll secure boot keys:"
echo "     sudo sbctl enroll-keys --microsoft"
echo "     Then enable Secure Boot in BIOS"
echo "  4. (Optional) Enroll TPM2 for LUKS auto-unlock:"
echo "     sudo systemd-cryptenroll $DISK_DEVICE<partition> --tpm2-device=auto --tpm2-pcrs=0+7"
echo "  5. Commit hardware-configuration.nix to the repo"
echo ""
echo "VS Code will download on first launch (mutable, self-updating)."
