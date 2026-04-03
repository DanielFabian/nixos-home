# HP ZBook Studio x360 G5 - Machine-specific configuration
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
    ../../modules/firmware/zfs.nix
    ../../modules/firmware/snapshots.nix
    ../../modules/firmware/nvidia.nix
    ../../modules/firmware/vms.nix
    ../../modules/desktop/steam.nix
  ];

  networking.hostName = "zbook";
  networking.hostId = "8425e349"; # required for ZFS

  # ZFS needs the zfs package available
  environment.systemPackages = with pkgs; [ zfs ];

  # Docker storage driver - ZFS on this host
  virtualisation.docker.storageDriver = "zfs";
}
