# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/e3cc120b-6139-4326-a26c-e3610d96b0d6";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/5CF2-A1D6";
      fsType = "vfat";
    };

  fileSystems."/mnt/backup/home" =
    { device = "backup/home";
      fsType = "zfs";
    };

  fileSystems."/mnt/data" =
    { device = "data/root";
      fsType = "zfs";
    };

  fileSystems."/mnt/data/home" =
    { device = "data/home";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/038f3a56-a5ba-4a8c-a4ed-0ff06635e6ac"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
