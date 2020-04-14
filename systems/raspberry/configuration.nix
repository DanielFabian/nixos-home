# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, nixpkgs,... }:
{
  imports = [ 
    ./hardware-configuration.nix
  ];

  boot.loader = {
    grub.enable = false; 
    generic-extlinux-compatible.enable = true;
  };

  networking.hostName = "raspberry";
  networking.firewall.allowedTCPPorts = [ 8443 ];

  users.users = {
    dany = {
      isNormalUser = true;
      description = "Daniel Fabian";
      home = "/home/dany";
      shell = pkgs.fish;

      extraGroups = [ "wheel" ];
    };
    root.shell = pkgs.fish;
  };
  
  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifiStable;
    openPorts = true;

    mongodbPackage = let
      channelRelease = "nixos-19.09pre190687.3f4144c30a6";  # last known working mongo
      channelName = "unstable";
      url = "https://releases.nixos.org/nixos/${channelName}/${channelRelease}/nixexprs.tar.xz";
      sha256 = "040f16afph387s0a4cc476q3j0z8ik2p5bjyg9w2kkahss1d0pzm";

      pinnedNixpkgsFile = builtins.fetchTarball {
        inherit url sha256;
      };

      pinnedNixpkgs = import pinnedNixpkgsFile {};
    in pinnedNixpkgs.mongodb;

    jrePackage = pkgs.jre8_headless;
  };
}
