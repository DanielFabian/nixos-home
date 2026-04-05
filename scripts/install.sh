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
PREPARE_ONLY=0
PREBUILT_SYSTEM=""

usage() {
  cat <<EOF
Usage:
  sudo ./scripts/install.sh <hostname> [--prepare-only]
  sudo ./scripts/install.sh <hostname> [--system /nix/store/...-nixos-system-...]

Modes:
  default         Partition, generate hardware config, build/install from flake
  --prepare-only  Partition, swapon, generate hardware config, then stop
  --system PATH   Install a prebuilt NixOS closure already present in /mnt/nix/store
EOF
}

maybe_activate_swap() {
  local swap_part
  swap_part=$(lsblk -lnp -o NAME,FSTYPE "$DISK_DEVICE" | awk '$2 == "swap" {print $1; exit}')
  if [[ -z "$swap_part" ]]; then
    return 0
  fi

  if swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$swap_part"; then
    echo "    Swap already active ($swap_part)."
  else
    echo "    Activating swap ($swap_part)..."
    swapon "$swap_part"
  fi
}

verify_target_store_mount() {
  if ! findmnt -M /mnt/nix >/dev/null; then
    echo "Error: /mnt/nix is not mounted on the target filesystem." >&2
    echo "If this is a fresh install, run without --system or with --prepare-only first." >&2
    findmnt /mnt >&2 || true
    exit 1
  fi

  echo "    Target store is mounted on disk:"
  findmnt /mnt/nix
}

prepare_tmpdir() {
  export TMPDIR=/mnt/.install-tmp
  mkdir -p "$TMPDIR"
}

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

HOST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepare-only)
      PREPARE_ONLY=1
      shift
      ;;
    --system|--closure|--store-path)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a store path argument" >&2
        usage >&2
        exit 1
      fi
      PREBUILT_SYSTEM="$2"
      shift 2
      ;;
    -h|--help)
      usage
      echo ""
      echo "Available hosts:"
      for h in "${valid_hosts[@]}"; do
        echo "  - $h"
      done
      exit 0
      ;;
    -*)
      echo "Error: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$HOST" ]]; then
        echo "Error: unexpected extra argument '$1'" >&2
        usage >&2
        exit 1
      fi
      HOST="$1"
      shift
      ;;
  esac
done

if [[ -z "$HOST" ]]; then
  usage
  echo ""
  echo "Available hosts:"
  for h in "${valid_hosts[@]}"; do
    echo "  - $h"
  done
  exit 1
fi

if [[ $PREPARE_ONLY -eq 1 && -n "$PREBUILT_SYSTEM" ]]; then
  echo "Error: --prepare-only and --system are mutually exclusive" >&2
  exit 1
fi

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
if [[ $PREPARE_ONLY -eq 1 ]]; then
  echo "Mode:  prepare-only"
elif [[ -n "$PREBUILT_SYSTEM" ]]; then
  echo "Mode:  install prebuilt closure"
else
  echo "Mode:  build from flake"
fi
echo ""
DISK_DEVICE=$(grep -oP 'device\s*=\s*"\K[^"]+' "$REPO_DIR/disko/$HOST.nix" | head -1)
echo "Target disk: $DISK_DEVICE"

if [[ -z "$PREBUILT_SYSTEM" ]]; then
  echo ""
  echo "WARNING: This will ERASE ALL DATA on $DISK_DEVICE"
  echo ""
  read -rp "Type 'yes' to continue: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi

  echo ""
  echo ">>> Step 1/4: Partitioning and formatting ($DISK_DEVICE)..."
  nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko "$REPO_DIR/disko/$HOST.nix"

  echo "    Disk partitioned and formatted."
  maybe_activate_swap
  verify_target_store_mount
  prepare_tmpdir

  echo ""
  echo ">>> Step 2/4: Generating hardware configuration..."
  nixos-generate-config --no-filesystems --root /mnt

  cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/hosts/$HOST/hardware-configuration.nix"
  echo "    Hardware config written to hosts/$HOST/hardware-configuration.nix"

  if [[ $PREPARE_ONLY -eq 1 ]]; then
  cat <<EOF

=== Prepare stage complete ===

Target disk is partitioned, swap is active, and hardware config has been generated.

To offload the heavy build to another machine:
  1. Copy hosts/$HOST/hardware-configuration.nix back to your builder machine.
  2. Build the exact closure there:
       nix build .#nixosConfigurations.$HOST.config.system.build.toplevel --print-out-paths --no-link
  3. From the builder machine, push that closure into this installer's target store:
      nix copy --no-check-sigs --to 'ssh-ng://root@<installer-ip>?remote-store=/mnt' /nix/store/<hash>-nixos-system-$HOST-...
  4. Then run:
       sudo ./scripts/install.sh $HOST --system /nix/store/<hash>-nixos-system-$HOST-...
EOF
    exit 0
  fi
else
  echo ""
  echo ">>> Using existing prepared target filesystem..."
  maybe_activate_swap
  verify_target_store_mount
  prepare_tmpdir

  if [[ ! -e "/mnt$PREBUILT_SYSTEM" ]]; then
    echo "Error: prebuilt closure not found in target store: $PREBUILT_SYSTEM" >&2
    echo "Push it first with:" >&2
    echo "  nix copy --no-check-sigs --to 'ssh-ng://root@<installer-ip>?remote-store=/mnt' $PREBUILT_SYSTEM" >&2
    exit 1
  fi
fi

echo ""
echo ">>> Installing NixOS (this takes a while)..."
if [[ -n "$PREBUILT_SYSTEM" ]]; then
  nixos-install --system "$PREBUILT_SYSTEM" --root /mnt --no-root-passwd
else
  nixos-install --flake "$REPO_DIR#$HOST" --no-root-passwd --max-jobs 1 --cores 1
fi

echo "    NixOS installed."

# Clean up temp dirs
rm -rf /mnt/.install-tmp

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
