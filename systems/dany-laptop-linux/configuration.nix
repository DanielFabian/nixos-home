# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../system-modules/shared.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };

    grub = {
      enable = true;
      version = 2;
      device = "nodev";
      efiSupport = true;
    };
  };

  services.xserver.videoDrivers = [ "intel" ];
#  hardware.nvidia.optimus_prime = {
#    enable = true;
#    intelBusId = "PCI:0:2:0";
#    nvidiaBusId = "PCI:3:0:0";
#  };
  hardware.bumblebee.enable = true;

  hardware.bluetooth.enable = true;

  networking.hostName = "dany-laptop-linux"; # Define your hostname.
  networking.hostId = "8425e349"; # needed for zfs.
#  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  systemd.user = {
    timers.feh = {
      enable = true;
      description = "Schedule: Change wallpaper every minute";
      timerConfig = { OnCalendar = "minutely"; Unit = "feh.service"; };
      wantedBy = [ "timers.target" ];
    };

    services.feh = {
      enable = true;
      description = "Change wallpaper";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.feh}/bin/feh --bg-fill --randomize /var/data/wallpapers/pics";
      };
    };
  };
}

