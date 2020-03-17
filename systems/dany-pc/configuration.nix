# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let evanjs_polychromatic = import (builtins.fetchGit {
  # Descriptive name to make the store path easier to identify
  name = "evanjs_polychromatic";
  url = https://github.com/evanjs/nixpkgs;
  # Commit hash for nixos-unstable as of 2018-09-12
  # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
  ref = "refs/heads/polychromatic/init";
  rev = "e738e50000050aca7d84dde1335dedd452359acb";
}) {};
in
with lib;
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../system-modules/shared.nix
      ./backup.nix
    ];

  environment.systemPackages = [ evanjs_polychromatic.polychromatic ];
 
  # Use the grub EFI boot loader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
 
    grub = {
      enable = true;
      version = 2;
      device = "nodev";
      efiSupport = true;
      gfxmodeEfi = "3840x2160";
      useOSProber = true;
    };
  };

  hardware.openrazer.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  networking.hostName = "dany-pc"; # Define your hostname.
  networking.hostId = "00ad07b0"; # needed for zfs.

  # for barrier
  networking.firewall.allowedTCPPorts = [ 24800 ];

  services.xserver.videoDrivers = [ "nvidia" ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  nix.extraOptions = ''
    secret-key-files = /root/.ssh/cache-priv-key.pem
    '';

  # set disable webkit compositing mode so that vimb can work.
  environment.variables.WEBKIT_DISABLE_COMPOSITING_MODE = "1";

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
    '';

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

    services.barriers = {
      enable = true;
      description = "KVM for remote controlling the laptop from the Desktop";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.barrier}/bin/barriers -f --enable-crypto -c ${./barrier.conf}";
      };
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
