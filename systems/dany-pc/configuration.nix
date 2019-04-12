# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
with lib;
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/internationalization.nix
      ../../modules/home-manager.nix
      ../../modules/users.nix
      ../../modules/fontconfig.nix
      ../../modules/numlock.nix
      ../../xmonad
    ];
  
  boot.supportedFilesystems = [ "ntfs" "zfs" ];
  
  # needed for zfs
  networking.hostId = "6d7416e5";
  services.zfs.autoScrub.enable = true;

  fileSystems."/mnt/1TB-USB" = 
    { device = "/dev/disk/by-partlabel/1TB-USB";
      fsType = "ntfs";
    };

  # Use the grub EFI boot loader.
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
      gfxmodeEfi = "3840x2160";
      useOSProber = true;
    };
  };

  networking.hostName = "dany-pc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";


  # Set your time zone.
  time.timeZone = "Europe/London";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    virtmanager
  ];

#  environment.systemPackages = with pkgs; [ rxvt_unicode ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
 
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  # supposedly cool shell: fish
  programs.fish.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  # globally allow unfree software, needed for drivers, etc.
  nixpkgs.config.allowUnfree = true;

  # have the system do updates regularly.
  system.autoUpgrade.enable = true;
  
  # No password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Apply terminal fonts asap during boot.
  boot.earlyVconsoleSetup = true;

  virtualisation.libvirtd.enable = true;
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };


}
