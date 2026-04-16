# Hyper-V Gen2 VM hardware configuration.
#
# Gen2 VMs are UEFI-only; disks appear via the hv_storvsc driver as /dev/sdX.
# sda = OS disk (built into the image), sdb = workspace disk (formatted on
# first boot by systemd.services.devhost-init-workspace).
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Hyper-V synthetic drivers. storvsc: disks. netvsc: network. utils: KVP.
  boot.initrd.availableKernelModules = [
    "hv_storvsc"
    "hv_vmbus"
    "hv_netvsc"
  ];
  boot.kernelModules = [ "hv_utils" ];

  # Root fs - nixos-generators (format=hyperv) labels the single root
  # partition "nixos". Keep in sync with that format's expectations.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Workspace disk. nofail so a missing sdb doesn't block boot (e.g. during
  # a rescue scenario). Labelled by devhost-init-workspace.service.
  fileSystems."/home" = {
    device = "/dev/disk/by-label/workspace";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=15s"
    ];
  };

  # Hyper-V provides time; don't fight it.
  services.timesyncd.enable = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
