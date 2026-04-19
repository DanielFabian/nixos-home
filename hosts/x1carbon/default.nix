# Lenovo ThinkPad X1 Carbon - Machine-specific configuration
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ../../modules/firmware/snapshots-btrfs.nix
  ];

  networking.hostName = "x1carbon";

  # Intel integrated graphics
  hardware.graphics.enable = true;

  # Wayland environment hints (no NVIDIA quirks needed)
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Docker storage driver - btrfs on this host
  virtualisation.docker.storageDriver = "btrfs";
}
