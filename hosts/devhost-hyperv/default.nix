# devhost-hyperv — disposable NixOS dev-container host for Hyper-V.
#
# Substrate-specific bits only; cattle invariants live in
# modules/devhost/default.nix.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devhost
  ];

  devhost = {
    autoUpgradeFlake = "github:DanielFabian/nixos-home#devhost-hyperv";
    osDisk = "/dev/sda";
    workspaceDevice = "/dev/sdb";
  };

  # Swapfile. Two roles under Hyper-V Dynamic Memory:
  #   (1) microsecond-latency overflow buffer that absorbs allocation spikes
  #       while the host's balloon driver takes its seconds to grant more RAM;
  #   (2) pressure beacon — kswapd activity / pswpout traffic is the loud,
  #       unambiguous signal the DM driver picks up to expand us faster.
  # Without swap a Linux guest under DM has no way to signal "I need more"
  # short of OOM-killing something. See mission 01KPN16EQ4T2KCBGR9SKATTNRG.
  # 16 GiB is conservative; bump if peak workloads are larger than this.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];

  # swappiness=10: prefer reclaiming page cache over swapping anon pages,
  # but allow swap when genuine pressure hits. Default of 60 is too eager
  # for a dev VM where we want anon pages hot.
  boot.kernel.sysctl."vm.swappiness" = 10;
}
