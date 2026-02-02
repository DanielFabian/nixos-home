# Networking configuration
{ config, pkgs, ... }:

{
  # NetworkManager - just works
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
  };

  # Firewall - permissive for local dev, lock down for prod
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
    ];
    # Allow container/VM traffic
    trustedInterfaces = [ "docker0" "virbr0" "podman0" ];
  };

  # Avahi for local discovery (useful for TrueNAS, printers)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # SSH server - firmware level
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
