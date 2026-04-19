#!/usr/bin/env bash
# install.sh — runs during devcontainer image build, BEFORE the /nix mount exists.
#
# We therefore can't read anything from /nix here. All we can do is:
#   1. Write profile.d / rc snippets that take effect at runtime.
#   2. Pre-configure nix.conf and direnv so they just work once /nix appears.
set -euo pipefail

ENABLE_DIRENV="${ENABLEDIRENV:-true}"
HOST_NIX_BIN_DIR="${HOSTNIXBINDIR:-/nix/devhost-sw-bin}"
HOST_NIXPKGS="${HOSTNIXPKGS:-/nix/devhost-nixpkgs}"

echo "nix-via-host: enableDirenv=$ENABLE_DIRENV hostNixBinDir=$HOST_NIX_BIN_DIR hostNixpkgs=$HOST_NIXPKGS"

# /etc/nix/nix.conf tells the nix client to talk to the daemon instead of
# trying to build locally. Experimental features match what you'd want for
# any modern nix workflow.
install -d -m 0755 /etc/nix
cat > /etc/nix/nix.conf <<EOF
experimental-features = nix-command flakes
# Route all store operations through the host's daemon via the mounted socket.
store = daemon
EOF

# /etc/nix/registry.json — pin the `nixpkgs` flake reference to the host's
# actual nixpkgs source. Without this, `nix run nixpkgs#ripgrep` would use
# the upstream default registry (github:NixOS/nixpkgs/nixpkgs-unstable) —
# which might work but wouldn't share derivations with the host. Pinning to
# the host path gives us perfect store-path parity.
cat > /etc/nix/registry.json <<EOF
{
  "version": 2,
  "flakes": [
    {
      "from": { "type": "indirect", "id": "nixpkgs" },
      "to":   { "type": "path",     "path": "$HOST_NIXPKGS" },
      "exact": true
    }
  ]
}
EOF

# /etc/profile.d is sourced by login shells. Most devcontainer terminals are
# interactive non-login, so we ALSO patch /etc/bash.bashrc and /etc/zsh/zshrc
# below. Having the profile.d file anyway makes `bash -l` and cron-style
# invocations work consistently.
install -d -m 0755 /etc/profile.d
cat > /etc/profile.d/10-nix-via-host.sh <<EOF
# Injected by the nix-via-host devcontainer Feature.
# Adds the host's shared tools to PATH. The symlink is maintained by the
# host's nixos-rebuild activation; if it doesn't exist, PATH is harmlessly
# polluted with a dead entry.
case ":\$PATH:" in
  *":$HOST_NIX_BIN_DIR:"*) ;;
  *) export PATH="$HOST_NIX_BIN_DIR:\$PATH" ;;
esac
export NIX_REMOTE=daemon
# NIX_PATH for legacy nix-shell / <nixpkgs>. Points at the host's actual
# nixpkgs source so store paths match the host bit-for-bit.
export NIX_PATH="nixpkgs=$HOST_NIXPKGS"

# Flake registry fix-up. The /etc/nix/registry.json written at image-build
# time points at \$HOST_NIXPKGS, which may itself be a symlink on the host.
# nix flake resolution dislikes symlink targets in "type=path" entries. So
# at shell start we regenerate a user-local registry pointing at the fully
# resolved realpath. User-local registry takes precedence over /etc/nix.
if [ -d "$HOST_NIXPKGS" ]; then
  _nixpkgs_real=\$(readlink -f "$HOST_NIXPKGS" 2>/dev/null || echo "$HOST_NIXPKGS")
  if [ -n "\$_nixpkgs_real" ] && [ -d "\$_nixpkgs_real" ]; then
    mkdir -p "\$HOME/.config/nix"
    cat > "\$HOME/.config/nix/registry.json" <<REG
{"version":2,"flakes":[{"from":{"type":"indirect","id":"nixpkgs"},"to":{"type":"path","path":"\$_nixpkgs_real"},"exact":true}]}
REG
  fi
  unset _nixpkgs_real
fi
EOF
chmod 0644 /etc/profile.d/10-nix-via-host.sh

# Patch interactive-shell rc files so VS Code's integrated terminal (which
# spawns a non-login interactive shell) gets the PATH too. We guard against
# double-appending in case the Feature is reinstalled.
append_once() {
  local file="$1"
  local marker="$2"
  local content="$3"
  [ -f "$file" ] || return 0
  if ! grep -qF "$marker" "$file" 2>/dev/null; then
    printf '\n%s\n%s\n' "$marker" "$content" >> "$file"
  fi
}

NIX_MARKER='# >>> nix-via-host >>>'
NIX_RC_SNIPPET=$(cat <<EOF
if [ -f /etc/profile.d/10-nix-via-host.sh ]; then . /etc/profile.d/10-nix-via-host.sh; fi
# <<< nix-via-host <<<
EOF
)

append_once /etc/bash.bashrc "$NIX_MARKER" "$NIX_RC_SNIPPET"
append_once /etc/zsh/zshrc   "$NIX_MARKER" "$NIX_RC_SNIPPET"

# direnv hook. Requires direnv and nix-direnv on the host's default PATH
# (this repo's hosts/devhost/nix-share.nix puts them in systemPackages).
# The hook fails soft: if direnv isn't on PATH it silently no-ops.
if [ "$ENABLE_DIRENV" = "true" ]; then
  install -d -m 0755 /etc/profile.d
  cat > /etc/profile.d/20-nix-via-host-direnv.sh <<'EOF'
# Injected by the nix-via-host devcontainer Feature.
# Activates direnv if present (install it on the host's NixOS system).
if command -v direnv >/dev/null 2>&1; then
  # Load nix-direnv if available so `use flake` / `use nix` work.
  NIX_DIRENVRC="$(command -v nix-direnv-reload 2>/dev/null || true)"
  if [ -n "$NIX_DIRENVRC" ]; then
    NIX_DIRENV_LIB="$(dirname "$NIX_DIRENVRC")/../share/nix-direnv/direnvrc"
    if [ -f "$NIX_DIRENV_LIB" ]; then
      export DIRENV_LIBRARY_PATH="${DIRENV_LIBRARY_PATH:-}:$(dirname "$NIX_DIRENV_LIB")"
    fi
  fi
  # Hook for whichever shell is sourcing this.
  case "${BASH_VERSION:-}${ZSH_VERSION:-}" in
    *?*) eval "$(direnv hook "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}")" ;;
  esac
fi
EOF
  chmod 0644 /etc/profile.d/20-nix-via-host-direnv.sh

  DIRENV_MARKER='# >>> nix-via-host-direnv >>>'
  DIRENV_RC_SNIPPET=$(cat <<EOF
if [ -f /etc/profile.d/20-nix-via-host-direnv.sh ]; then . /etc/profile.d/20-nix-via-host-direnv.sh; fi
# <<< nix-via-host-direnv <<<
EOF
)
  append_once /etc/bash.bashrc "$DIRENV_MARKER" "$DIRENV_RC_SNIPPET"
  append_once /etc/zsh/zshrc   "$DIRENV_MARKER" "$DIRENV_RC_SNIPPET"
fi

echo "nix-via-host: installed. Runtime requirements: /nix bind-mounted, host nix daemon reachable, uid in host's nix.settings.trusted-users."
