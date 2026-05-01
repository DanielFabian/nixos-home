# devhost-hyperv installer — thin wrapper over modules/devhost/installer.nix.
{
  ...
}:

{
  imports = [
    ../../modules/devhost/installer.nix
  ];

  devhost = {
    osDisk = "/dev/sda";
    installer = {
      flakeUrl = "github:DanielFabian/nixos-home";
      hostAttr = "devhost-hyperv";
      ejectDevice = "/dev/sr0"; # Hyper-V exposes attached ISO as SCSI cdrom
      # SSH pubkeys allowed into the *installer environment* (debug only).
      authorizedKeys = (import ../../modules/devhost/authorized-keys.nix).keys;
    };
  };
}
