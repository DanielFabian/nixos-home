#!/usr/bin/env bash
# Sync nixpkgs as a shallow clone for grepping
# This is NOT a submodule - just a reference corpus

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIXPKGS_DIR="$REPO_ROOT/nixpkgs"
NIXPKGS_REPO="https://github.com/NixOS/nixpkgs.git"
BRANCH="nixos-unstable"  # or nixos-24.11 for stable

if [[ -d "$NIXPKGS_DIR/.git" ]]; then
    echo "Updating existing nixpkgs clone..."
    cd "$NIXPKGS_DIR"
    git fetch --depth=1 origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
else
    echo "Cloning nixpkgs (shallow, blobless)..."
    rm -rf "$NIXPKGS_DIR"
    git clone \
        --depth=1 \
        --filter=blob:none \
        --branch="$BRANCH" \
        --single-branch \
        "$NIXPKGS_REPO" \
        "$NIXPKGS_DIR"
fi

echo ""
echo "nixpkgs synced to $BRANCH"
echo "Size: $(du -sh "$NIXPKGS_DIR" | cut -f1)"
echo ""
echo "Usage: rg 'services.xserver' nixpkgs/nixos/"
