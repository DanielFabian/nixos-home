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
  boot.supportedFilesystems = [ "zfs" ];

  fileSystems."/" =
    { device = "system/nixos/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "system/nixos/home/home";
      fsType = "zfs";
    };

  fileSystems."/root" =
    { device = "system/nixos/home/root";
      fsType = "zfs";
    };

  fileSystems."/var" =
    { device = "system/nixos/var";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "system/nix";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BAE6-45EF";
      fsType = "vfat";
    };

  fileSystems."/var/data" =
    { device = "data";
      fsType = "zfs";
    };

  fileSystems."/var/backup" =
    { device = "backup";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system" =
    { device = "backup/system";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system/nixos" =
    { device = "backup/system/nixos";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system/nixos/root" =
    { device = "backup/system/nixos/root";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system/nixos/home/home" =
    { device = "backup/system/nixos/home/home";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system/nixos/home/root" =
    { device = "backup/system/nixos/home/root";
      fsType = "zfs";
    };

  fileSystems."/var/backup/system/nixos/var" =
    { device = "backup/system/nixos/var";
      fsType = "zfs";
    };

  fileSystems."/var/backup/data" =
    { device = "backup/data";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/39bf21f0-95d8-446b-b55f-d334730c1328"; }
      { device = "/dev/disk/by-uuid/7c32448d-6f2d-4938-ac2e-03acbf8d796d"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
