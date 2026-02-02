# ZFS configuration
{ config, pkgs, ... }:

{
  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # ZFS arc size - with 32GB RAM, we can be generous
  # But let's not go crazy - leave room for apps
  boot.kernelParams = [
    "zfs.zfs_arc_max=${toString (8 * 1024 * 1024 * 1024)}"  # 8GB max ARC
  ];
}
