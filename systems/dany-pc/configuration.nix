# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
with lib;
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../system-modules/shared.nix
      ./backup.nix
    ];
 
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

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
    '';

}
