# nix-via-host — DevContainer Feature

Share the host's `/nix/store` and nix daemon into a devcontainer, so:

- No per-container Nix install (0 bytes added to image).
- First `nix profile install nixpkgs#ripgrep` downloads once, forever.
- Every devcontainer on the same host reuses every path.
- `nix develop` / `nix-shell` / `flake`s / `.envrc` all work normally.

## When this makes sense

You have a **devhost**: a NixOS machine you SSH into to host your devcontainers
(Hyper-V VM, remote workstation, etc.) On that host:

- The nix daemon runs (`nix.enable = true;` — the NixOS default).
- Your user is in `nix.settings.trusted-users`.
- A symlink `/nix/devhost-sw-bin` points at the system's `sw/bin` (see
  `hosts/devhost/nix-share.nix` in this repo for the reference host-side
  setup).

If you're on a regular laptop with Docker Desktop and no nix daemon, use
[devcontainers-contrib/features/nix](https://github.com/devcontainers-contrib/features/tree/main/src/nix)
instead — that Feature installs Nix *inside* the container, which is
portable but doesn't dedupe.

## Using it

In your `devcontainer.json`:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/danielfabian/nixos-home/nix-via-host:0": {}
  }
}
```

The `:0` tag tracks the current 0.x line. Pin to `:0.2.0` if you want
exact version immutability. Reference the feature by local path
(`"./features/nix-via-host": {}`) when iterating on it in this repo.

The Feature contributes:

- A bind mount of `/nix` (rw).
- `NIX_REMOTE=daemon` in the container env.
- `/nix/devhost-sw-bin` prepended to `PATH` for login and interactive shells.
- Optional direnv hook (enabled by default; disable with `{ "enableDirenv": false }`).

## Options

| Option | Default | Description |
|---|---|---|
| `enableDirenv` | `true` | Hook direnv in bash/zsh so `.envrc` (`use flake`) auto-loads. Requires `direnv` + `nix-direnv` on the host's system PATH. |
| `hostNixBinDir` | `/nix/devhost-sw-bin` | Where the host exposes its tools. Change if you symlink elsewhere. |

## Troubleshooting

**`nix` not found in container after rebuild.** The host's
`/nix/devhost-sw-bin` symlink might be missing. On the host:
`ls -l /nix/devhost-sw-bin`. It should point at a store path. If not, the
host's `system.activationScripts.devhostContainerTools` didn't run — re-run
`nixos-rebuild switch`.

**`error: permission denied` from daemon.** Your container user's uid doesn't
map to a name in the host's `trusted-users`. Check:
`id -u` in container, then on the host verify `/etc/passwd` has that uid
and that name is in `nix.settings.trusted-users`.

**direnv doesn't hook.** `which direnv` inside the container — if empty, the
host doesn't have direnv in its system path. Add `direnv` and `nix-direnv`
to the host's `environment.systemPackages` and rebuild.
