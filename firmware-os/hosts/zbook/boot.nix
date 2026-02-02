# ZBook-specific boot configuration (LUKS, etc)
{ config, lib, ... }:

{
  # LUKS device - explicit config for systemd initrd
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/3172100e-7d6b-4eea-8d8d-fcfe638c30f8";
    allowDiscards = true;
    bypassWorkqueues = true;  # SSD performance
  };
}
