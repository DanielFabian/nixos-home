# Boot configuration - systemd-boot initially, lanzaboote after secure boot setup
{ config, pkgs, lib, ... }:

{
  # Phase 1: systemd-boot (before secure boot)
  # After secure boot is configured, this gets replaced by lanzaboote
  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;  # overridden by lanzaboote
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
    timeout = 3;
  };

  # Lanzaboote config (activate after initial install + key enrollment)
  # boot.loader.systemd-boot.enable = lib.mkForce false;
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/etc/secureboot";
  # };

  # LUKS - disko handles the actual setup, this is runtime config
  boot.initrd = {
    availableKernelModules = [ 
      "xhci_pci" 
      "ahci" 
      "nvme" 
      "usb_storage" 
      "sd_mod"
      # ZFS
      "zfs"
    ];
    
    # Systemd in initrd for cleaner boot + TPM2 support
    systemd.enable = true;
    
    # TODO: TPM2 auto-unlock after secure boot
    # systemd.tpm2.enable = true;
  };

  # Kernel - use default stable LTS (ZFS compatible)
  # If ZFS breaks with default kernel, pin explicitly:
  # boot.kernelPackages = pkgs.linuxPackages_6_6;
  
  # ZFS kernel module
  boot.supportedFilesystems = [ "zfs" ];
}
