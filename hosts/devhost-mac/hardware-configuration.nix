# Apple Virtualization (aarch64) hardware configuration.
#
# Apple's Virtualization.framework presents disks as virtio-blk (/dev/vd*)
# and the network as virtio-net. UEFI-only, no legacy BIOS.
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

  # virtio drivers for Apple Virtualization. Kept minimal — the framework
  # exposes only virtio-blk, virtio-net, virtio-rng, and a virtio-console.
  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_net"
    "virtio_rng"
  ];

  # Root fs — installer formats /dev/vda2 with label "nixos".
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Workspace disk — labelled by devhost-init-workspace.service. nofail so
  # a missing vdb doesn't block boot (e.g. during a rescue scenario).
  fileSystems."/home" = {
    device = "/dev/disk/by-label/workspace";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=15s"
    ];
  };

  # Apple Virtualization provides time via virtio-rtc; don't fight it.
  services.timesyncd.enable = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
