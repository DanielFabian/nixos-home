# Virtualization - Docker + libvirt (firmware layer)
{ config, pkgs, ... }:

{
  # Docker - rootless option available but rootful is simpler for devcontainers
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # ZFS storage driver
    storageDriver = "zfs";
  };

  # Libvirt for VMs
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;  # TPM emulation for Windows VMs
      # OVMF is now available by default, no explicit config needed
    };
  };

  # Podman as Docker alternative (can coexist)
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;  # don't override docker command
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable IP forwarding for containers
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # User groups added in users/dany.nix
}
