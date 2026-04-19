# Host-side support for the `nix-via-host` devcontainer Feature.
#
# Contract with the Feature:
#   - Containers bind-mount /nix from the host.
#   - A stable symlink /nix/devhost-sw-bin points at the current system's
#     /bin directory (a store path, so reachable from inside containers).
#   - `dany` is in nix.settings.trusted-users (already set in default.nix),
#     so clients connecting as uid 1000 (dany) authenticate without fuss.
#
# Pre-provisioned tools: anything in environment.systemPackages on the host
# is visible to containers via /nix/devhost-sw-bin. direnv + nix-direnv are
# added here so `direnv allow` in a repo with a .envrc "just works" inside
# the container.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    direnv
    nix-direnv
  ];

  # Stable, container-reachable paths. Refreshed on every nixos-rebuild
  # switch via activation scripts. Long-running containers keep pointing at
  # the old store paths until they reopen PATH entries; that's fine — store
  # paths are immutable and not GC'd while referenced.
  #
  # /nix/devhost-sw-bin → the system's sw/bin (host's systemPackages).
  # /nix/devhost-nixpkgs → the nixpkgs source flake this system was built
  #   from. Containers reference it via NIX_PATH + flake registry so that
  #   `nix-shell -p ripgrep` and `nix run nixpkgs#ripgrep` resolve to the
  #   EXACT same derivation the host would build — instant cache hit, zero
  #   duplication.
  system.activationScripts.devhostContainerTools = {
    text = ''
      ln -sfn ${config.system.path}/bin /nix/devhost-sw-bin
      # pkgs.path can itself be a symlink (lazy-trees / flake indirection).
      # The flake registry refuses a "type=path" pointing at a symlink, so
      # we resolve the chain here and point /nix/devhost-nixpkgs directly
      # at the underlying real directory.
      nixpkgs_real=$(readlink -f ${pkgs.path})
      ln -sfn "$nixpkgs_real" /nix/devhost-nixpkgs
    '';
    deps = [ ];
  };

  # Advertise the shared-tools path in the MOTD so first-time SSH shows
  # the contract. Append to whatever devhost-user-ssh-key.service wrote.
  # (We don't own /etc/motd; we add a drop-in.)
  environment.etc."motd.d/10-nix-share.txt".text = ''

    nix-via-host devcontainer Feature:
      bind-mount /nix into your container (the Feature does this)
      PATH includes /nix/devhost-sw-bin (host's systemPackages)
      NIX_PATH pinned to /nix/devhost-nixpkgs (host's nixpkgs)
      NIX_REMOTE=daemon routes nix commands to this host's daemon
  '';
}
