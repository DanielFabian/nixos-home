# Boot configuration - systemd-boot initially, lanzaboote after secure boot setup
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Phase 1: systemd-boot (before secure boot)
  # After secure boot is configured, this gets replaced by lanzaboote
  boot.loader = {
    systemd-boot.enable = lib.mkDefault true; # overridden by lanzaboote
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
      # TPM2
      "tpm_crb"
      "tpm_tis"
    ];

    # Systemd in initrd - required for TPM2 auto-unlock
    systemd.enable = true;

    # TPM2 auto-unlock for LUKS
    # After first boot, enroll TPM2 with:
    #   sudo systemd-cryptenroll /dev/nvme0n1p3 --tpm2-device=auto --tpm2-pcrs=0+7
    # PCR 0 = firmware, PCR 7 = secure boot state
    # Add --wipe-slot=tpm2 to re-enroll if needed
    systemd.tpm2.enable = true;
  };

  # Kernel - use default stable LTS (ZFS compatible)
  # If ZFS breaks with default kernel, pin explicitly:
  # boot.kernelPackages = pkgs.linuxPackages_6_6;

  # ZFS kernel module
  boot.supportedFilesystems = [ "zfs" ];
}
