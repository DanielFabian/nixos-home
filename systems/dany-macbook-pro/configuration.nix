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
      ../../system-modules/wifi.nix
      ../../system-modules/dist-builds.nix
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
  
  # backlight
  services.xserver.extraDisplaySettings = ''
    Option "RegistryDwords" "EnableBrightnessControl=1"
    '';

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # NVIDIA drivers for MacBook Pro. Doesn't work in EFI!
  services.xserver.videoDrivers = [ "nvidiaLegacy340" ];

  # MacBook Pro drivers for keyboard background color and volumen control, etc.
  services.hardware.pommed.enable = true;
}
