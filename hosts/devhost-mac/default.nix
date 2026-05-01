# devhost-mac — disposable NixOS dev-container host for Apple Virtualization
# on Apple Silicon (aarch64). Counterpart to devhost-hyperv.
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
    autoUpgradeFlake = "github:DanielFabian/nixos-home#devhost-mac";
    osDisk = "/dev/vda";
    workspaceDevice = "/dev/vdb";
  };

  # Swapfile rationale on this variant differs from Hyper-V: Apple
  # Virtualization assigns fixed RAM at VM-create time (no balloon driver),
  # so swap is not a "pressure beacon" — it's just OOM ergonomics. Agentic
  # tools have a demonstrated bias toward filling RAM (duplicate processes,
  # /tmp, leaked workers); without swap that becomes a hard OOM-kill that
  # nukes ssh sessions before you can react. With swap it becomes thrash you
  # can notice. 8 GiB on a regenerable VM disk is rounding error.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # MiB
    }
  ];
}
