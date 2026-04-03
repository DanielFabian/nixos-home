# Libvirt VMs (firmware layer) - optional, for hosts with enough disk/RAM
{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulation for Windows VMs
    };
  };

  # User groups added in users/dany.nix
}
