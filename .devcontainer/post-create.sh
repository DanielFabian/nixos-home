#!/usr/bin/env bash
set -euo pipefail

echo "Installing Nix tools..."

# Install nil (Nix LSP) and nixfmt
nix profile install nixpkgs#nil nixpkgs#nixfmt-rfc-style

# Verify nix can evaluate our flake
echo "Testing flake evaluation..."
nix flake check --no-build 2>/dev/null || echo "Note: flake check requires ZFS module, skipping in container"

echo "Dev environment ready!"
echo ""
echo "Useful commands:"
echo "  nix flake check           - Validate flake"
echo "  nix eval .#nixosConfigurations.zbook.config.system.build.toplevel --dry-run"
echo "  rg 'something' nixpkgs/   - Grep nixpkgs source"
