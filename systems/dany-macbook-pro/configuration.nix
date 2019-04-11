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

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    version = 2;
    gfxmodeBios = "1280x800";

    # make the text-only terminal have good resolution
    gfxpayloadBios = "keep";

    device = "/dev/sda"; # or "nodev" for efi only
  };

  networking.hostName = "dany-macbook-pro"; # Define your hostname.
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
  
  # backlight
  services.xserver.extraDisplaySettings = ''
    Option "RegistryDwords" "EnableBrightnessControl=1"
    '';

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

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

  # MacBook Pro drivers for keyboard background color and volumen control, etc.
  services.hardware.pommed.enable = true;

  # NVIDIA drivers for MacBook Pro. Doesn't work in EFI!
  services.xserver.videoDrivers = [ "nvidiaLegacy340" ];

  # No password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Apply terminal fonts asap during boot.
  boot.earlyVconsoleSetup = true;

  virtualisation.libvirtd.enable = true;
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
}
