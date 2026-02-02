#!/usr/bin/env bash
# Sync home-manager as a shallow clone for grepping
# This is NOT a submodule - just a reference corpus
# Pinned to flake.lock to avoid drifting from the configuration.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HM_DIR="$REPO_ROOT/home-manager"
HM_REPO="https://github.com/nix-community/home-manager.git"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (to read flake.lock)" >&2
  exit 1
fi

REV="$(jq -r '.nodes["home-manager"].locked.rev // empty' "$REPO_ROOT/flake.lock")"
if [[ -z "$REV" ]]; then
  echo "error: could not find home-manager locked.rev in flake.lock" >&2
  exit 1
fi

if [[ -d "$HM_DIR/.git" ]]; then
  echo "Updating existing home-manager clone..."
  cd "$HM_DIR"
  git fetch --depth=1 origin "$REV"
  git reset --hard FETCH_HEAD
else
  echo "Cloning home-manager (shallow)..."
  rm -rf "$HM_DIR"
  git clone --filter=blob:none "$HM_REPO" "$HM_DIR"
  cd "$HM_DIR"
  git fetch --depth=1 origin "$REV"
  git reset --hard FETCH_HEAD
fi

echo ""
echo "home-manager synced to $REV"
echo "Size: $(du -sh "$HM_DIR" | cut -f1)"
echo ""
echo "Usage: rg 'programs.zsh' home-manager/"
