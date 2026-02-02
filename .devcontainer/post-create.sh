#!/usr/bin/env bash
set -euo pipefail

echo "Installing Nix tools..."

# Install nil (Nix LSP), nixfmt, and ripgrep
nix profile install nixpkgs#nil nixpkgs#nixfmt-rfc-style nixpkgs#ripgrep nixpkgs#nodejs_22

# Install MCP server dependencies
if [[ -f tools/nixos-mcp/package.json ]]; then
    echo "Installing MCP server dependencies..."
    cd tools/nixos-mcp && npm install && cd ../..
fi

# Clone nixpkgs for grepping (shallow, inside container)
if [[ ! -d nixpkgs/.git ]]; then
    echo "Cloning nixpkgs (shallow) for grepping..."
    git clone --depth=1 --filter=blob:none --branch=nixos-unstable --single-branch \
        https://github.com/NixOS/nixpkgs.git nixpkgs
fi

# Verify nix can evaluate our flake
echo "Testing flake evaluation..."
nix flake check --no-build 2>/dev/null || echo "Note: flake check requires ZFS module, skipping in container"

echo "Dev environment ready!"
echo ""
echo "Useful commands:"
echo "  nix flake check           - Validate flake"
echo "  nix eval .#nixosConfigurations.zbook.config.system.build.toplevel --dry-run"
echo "  rg 'something' nixpkgs/   - Grep nixpkgs source"
