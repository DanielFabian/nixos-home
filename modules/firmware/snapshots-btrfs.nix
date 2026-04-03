# Snapshot automation with btrbk (for btrfs hosts)
# Equivalent to sanoid on ZFS: automated snapshot rotation
{ config, pkgs, ... }:

{
  services.btrbk.instances.default = {
    onCalendar = "*:0/15"; # every 15 minutes
    settings = {
      snapshot_preserve_min = "2h";
      snapshot_preserve = "48h 30d 8w 3m";
      snapshot_dir = "/.snapshots";

      volume."/" = {
        subvolume."@home" = {
          snapshot_create = "always";
        };
        subvolume."@persist" = {
          snapshot_create = "always";
        };
        subvolume."@root" = {
          snapshot_create = "always";
          # Root is less precious - lighter retention
          snapshot_preserve_min = "1h";
          snapshot_preserve = "24h 7d 4w";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];
}
