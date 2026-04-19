# Docker + Podman - Container runtime (firmware layer)
{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Podman as secondary runtime (can coexist)
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # don't override docker command
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable IP forwarding for containers
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # User groups added in users/dany.nix
}
